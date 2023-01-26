# Introduction
Detecting using a Random Forest Classifier the emergence of collusion in Prisoner Dilemma games played by two reinforcement learning algorithms 

This repository contains the project I have devloped for my Bachelor's thesis in Economics and Finance at the University of Bologna. If you find this topic particlarly interesing you can read all my thesis [here](https://drive.google.com/drive/folders/1YdH2UBitbpYkWG83-rfi_8CWcSFTyeVC?usp=share_link). 


# Project overview
Starting from the research carried out in [this paper](https://www.aeaweb.org/articles?id=10.1257/aer.20190623) it is knwon that **algorithmic pricing softwares power by Reinforcement Learning can autonomously learn to collude**. This paper addresses the question
> When and how is it possible to detect the beginning of tacit collusive behaviour between reinforcement algorithmic powered agents?

# Problem definition
Due to the characteristics of the [Prisoner's Dilemma game](https://www.investopedia.com/terms/p/prisoners-dilemma.asp#:~:text=Understanding%20the%20Prisoner's%20Dilemma&text=The%20prisoner's%20dilemma%20presents%20a,parties%20choose%20to%20co%2Doperate), players make 1 move at a time, and move after move a `time series` is created with scores for the optimal next move. 
Scores vary around 0, sometimes they are postive and sometimes negative, depding on the sign, the RL algorihm will undertake cooperation or defection. At some the scores take values that keep on being strictly positive or strictly negative values (depending on the current state) and label that moment as the one where collusion begins. 
Let's look at an image so that it becomes easier to understand.

![alt text](https://github.com/manuelrech/Collusion/blob/main/images/zoom0.png)

Every line refers to a current state 
- red (CC) both cooperate -> collusive state
- black (DD) both defect 
- blue (DC) one defect and the other cooperates
- green (CD) opposite of the blue line
And the score (dQ) indicates what the next action will be:
- positve -> next action defect
- negative -> next action cooperate

The pattern you see in this picture is the same in all experiments, the red line departs from zero sooner than all the others, then after some thousand iterations also the other 3 lines take strictly positive or negative values. 

We can define collusion as the moment in which both agents cooperate and will keep on cooperating for the next moves, so maintain collusion. Visually it is simple to see this moment, is the red line becoming negative forever, and to give a `date` to this event we can zoom in and see the exact iteration 


![alt text](https://github.com/manuelrech/Collusion/blob/main/images/zooming_process.jpeg)

For this experiment is iteration 159290

## Featues engineering
After having gone through all the critical dates, in which the previous iteration is non-negative and the following is negative, we have labeled which is the switch date (date in which the red CC line becomes strictly negative). 

Now i have created moving averages on different periods for every critical date, for states CC, DD and DC:
- 100 interations before and after ml100, mu100
- 500 interations before and after ml500, mu500
- ml1000, mu1000
- ml3000, mu3000
- ml5000, mu5000
- ml8000, mu8000
- ml30000, mu30000
- ml50000, mu50000

## Random forest classifier
A RFC has been trained and tested on unseen data and the most relevant fetures turned out to be all averages on the CC red line but also the longest averages on the DC blue line. Here's the variable importance plot of this classifier

![alt text](https://github.com/manuelrech/Collusion/blob/main/images/var_imp_plot.png)

## Results
The random forest has been trained with 2000 sessions (1000 per agent) and has been tested with the same number of unknown observations. 

Here's the ROC curve for test data with the same settings as the train

![alt text](https://github.com/manuelrech/Collusion/blob/main/images/var_imp_plot.png)



