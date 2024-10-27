// Connect to the Ethereum provider and contract
const provider = new ethers.providers.Web3Provider(window.ethereum, "any"); 
provider.on("network", (newNetwork, oldNetwork) => { if (oldNetwork) { window.location.reload(); } });

const signer = provider.getSigner();
const praceAddress = "0x5b6b8505c4e53340Ba7bd46Eaea3d4b2dce94F82";
const praceContract = new ethers.Contract(praceAddress, praceABI, signer);

// Global variables
let startTime;
let bettingWindow;
let countdownInterval;
const horses = [
    { name: '0 - FLR', price: 0, percent: 0 },
    { name: '1 - SGB', price: 0, percent: 0 },
    { name: '2 - XRP', price: 0, percent: 0 },
    { name: '3 - XLM', price: 0, percent: 0 },
    { name: '4 - LTC', price: 0, percent: 0 },
    { name: '5 - ETH', price: 0, percent: 0 },
    { name: '6 - BTC', price: 0, percent: 0 },
    { name: '7 - POL', price: 0, percent: 0 }
];

// Initialize horse display
document.addEventListener("DOMContentLoaded", async () => {
    await connectWallet();
    await initializeRaceData();
    displayHorses();
    startCountdown();
});

// Connect to wallet
async function connectWallet() {
    await ethereum.request({ method: 'eth_requestAccounts' });
    await refreshPage();
}

// Get initial race data from the contract
async function initializeRaceData() {
    startTime = await praceContract.startTime();
    bettingWindow = await praceContract.bettingWindow();
    updateHorseData();
}

// Update horse data (prices and percent changes) from the contract
async function updateHorseData() {
    const prices = await praceContract.getAllPrices();
    const percentChanges = await praceContract.getCurrentPercentChanges();

	prices.forEach((price, i) => {
		horses[i].price = price; // Use the raw BigNumber for price
		horses[i].percent = percentChanges[i].gte(0) ? percentChanges[i] : ethers.BigNumber.from(0); // Set to 0 if negative
	});

    moveHorses();
}

// Display horses and their positions based on percent increases

function displayHorses() {
    const horseContainer = document.getElementById("horseContainer");
    horseContainer.innerHTML = ""; // Clear any existing elements once

    horses.forEach((horse, i) => {
        const horseDiv = document.createElement("div");
        horseDiv.className = "horse";
        horseDiv.innerHTML = `
            <div class="horse-name" id="horse-name-${i}">${horse.name}: $${horse.price.toString()} - (${horse.percent.toString()}%)</div>
            <div class="track">
                <div class="horse-runner" id="runner-${i}" style="width: 0%;"></div>
            </div>
        `;
        horseContainer.appendChild(horseDiv);
    });
}


function moveHorses() {
    const maxPercent = Math.max(...horses.map(h => h.percent.toNumber())); // Get maximum percent increase as a number

    horses.forEach((horse, i) => {
        // Calculate position as a percentage of the track width, with max position at 75%
        const positionPercent = horse.percent.gt(0)
            ? Math.min(75, (horse.percent.toNumber() * 75) / maxPercent)
            : 0;

        // Update the position of the runner on the track
        document.getElementById(`runner-${i}`).style.width = `${positionPercent}%`;

        // Format the percent for 4 decimal places by dividing by 10000
        const formattedPercent = (horse.percent.toNumber() / 10000).toFixed(4); // Pads to 4 decimals

        // Update the display text with price and formatted percent
        document.getElementById(`horse-name-${i}`).textContent = `${horse.name}: $${horse.price.toString()} (${formattedPercent}%)`;
    });
}

// Start countdown timer for betting window
function startCountdown() {
    const countdown = document.getElementById("timeLeft");

    countdownInterval = setInterval(async () => {
        const currentTime = Math.floor(Date.now() / 1000);
        const timeElapsed = currentTime - startTime;
        const timeRemaining = bettingWindow - timeElapsed;

        if (timeRemaining > 0) {
            countdown.textContent = timeRemaining;
        } else {
            clearInterval(countdownInterval);
            countdown.textContent = "Betting closed";
        }
    }, 1000);
}

// Place a bet on a specific coin
async function placeBet() {
    const coinIndex = parseInt(document.getElementById("coinSelect").value);
    const betAmount = document.getElementById("betAmount").value;

    if (coinIndex < 0 || coinIndex > 7) {
        alert("Invalid coin index. Enter a number between 0 and 7.");
        return;
    }

    try {
        const tx = await praceContract.placeBet(coinIndex, { value: ethers.utils.parseEther(betAmount) });
        await tx.wait();
        alert("Bet placed successfully!");
    } catch (error) {
        alert("Error placing bet: " + error.message);
    }
}

async function updateContractBalance() {
    try {
        // Fetch the contract balance in Wei
        const balanceWei = await provider.getBalance(praceAddress);

        // Convert balance from Wei to Ether and display it
        const balanceEth = ethers.utils.formatEther(balanceWei);
        document.getElementById("contractBalance").textContent = parseFloat(balanceEth).toFixed(2); 
    } catch (error) {
        console.error("Error fetching contract balance:", error);
    }
}

// Refresh horse data periodically
async function refreshPage() {
    setInterval(async () => {
        await updateHorseData();
		await updateContractBalance();
		
        moveHorses(); // Only update positions and text without clearing elements
    }, 10000); // Refresh every 10 seconds
}