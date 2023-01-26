# Introduction
Detecting using Random Forest the emergence of collusion in Prisoner Dilemma games played by two reinforcement learning algorithms 

This repository contains the project I have devloped for my Bachelor's thesis in Economics and Finance at the University of Bologna. If you find this topic particlarly interesing you can read all my thesis [here](https://drive.google.com/drive/folders/1YdH2UBitbpYkWG83-rfi_8CWcSFTyeVC?usp=share_link). 


# Project overview
Starting from the research carried out in [this paper](https://www.aeaweb.org/articles?id=10.1257/aer.20190623) it is knwon that **algorithmic pricing softwares power by Reinforcement Learning can autonomously learn to collude**. This paper addresses the question
> When and how is it possible to detect the beginning of tacit collusive behaviour between reinforcement algorithmic powered agents?

# Problem definition
Due to the characteristics of the Prisoner's Dilemma game, players make 1 move at a time, and move after move a `time series` is created with scores for the optimal next move. At some point scores take some 
