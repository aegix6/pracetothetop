# Prace To The Top
Encode Hackathon - FLARE - Track 2 - Using FTSO

Live Demo: http://topdapps.xyz/pracetothetop/

![image](https://github.com/user-attachments/assets/0d8f10b6-2835-4f5b-b8c6-8c528956626c)

The concept is relatively straightforward. 

8 of my favorite coins (in order from FLR down to POL) are listed as horses. 

The initial timestamp is recorded, as are all 8 coins current prices from the FTSO. 

There is a betting window in which users place an amount of FLR (1 to 100 (variable set min/max)) ,  after more time has elapsed, the owner runs the 'finishRace' function, which takes the current prices again, and calculates the 'winning' horse based on PERCENT increased from the beginning. 

The betting window should be 10% of total time of the race, or around there.  So if each race should last one hour, then the betting should only open for the first 10 minutes, as any more would give some an unfair advantage. 

In a much shorter time frame, and more frequent races, we would say maybe 2 minutes betting window, and then 8 minutes of cheering and watching your horse. 


The finishRace function should be automatically run by a bot wallet which has been given ownership of the contract to automate the process. The function simultanously starts a new race as it finishes the old one and pays out the winners, who are paid out from the total balance of the contract in proportion to their bets. 


There are still some optimizations that would be good to implement in the long run; but it seems to work as intended currently.  With an upgraded UI and animations etc. it could be a fun way to use Live Pricing data to have some gambling fun. 


Thanks for your consideration Flare Team. 

-Peter Aegix
