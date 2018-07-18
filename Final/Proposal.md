# Video Game Recommender System
_DATA 643 Final Project Proposal_

## Team Members

The members for the final project group are:

- Kai Lukowiak
- Ilya Kats
- Jaan Brenberg

## Objective and Approach

The main objective of the project is to build a recommender system using a large data set in a cloud-hosted Spark distributed computing environment. For the recommender element, we plan to explore various options for filtering, adding/selecting features, building hybrid recommender algorithm. Projects 1 through 4 provided general idea of basic options to try and compare. Project 5 will provide some distributed environment experience. With large data set, performance will be a significant factor in recommender system selection. We plan to build a working algorithm that will make recommendations based on prior information. A fully working application/interface is not covered by this project.

## Data Set

We will use the [Amazong video game
ratings](http://jmcauley.ucsd.edu/data/amazon/links.html) data set and concentrate specifically on the Video Game category. This data set is provided by Julian McAuley at UC San Diego. This is a new data set for everyone on the team. We have chosen it because it provides necessary information to employ various approaches we have learned in this class, such as user-user collaborative filtering or item based filtering.

## Challenges

We expect one of the hardest parts to be the database and distributed computing environment administration. While implementing ALS, SVD, or TF-IDF within Spark's MLLib might not be difficult, integrating these into a hybrid system may be challenging. Additionally, this being a shortened summer class, time resources to investigate everything fully is more limited than usual.

