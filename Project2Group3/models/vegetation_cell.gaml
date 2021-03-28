/**
* Name: Vegetation Cell (DPS Project 2 - Sheep vs. Wolves)
* Group: 3
* Group members:
* 	202001351 - Micha Heiß
* 	201902778 - Denis Hlinka
* 	201911250 - Tereza Madova
* 	201911260 - Mircea Melinte
* 	201910044 - Peter Miodrag Varanic
*/

model vegetation_cell

grid vegetation_cell width: 50 height: 50 neighbors: 4 {
	float max_food <- 1.0;
    float food_prod <- rnd(0.01);
    float food <- rnd(1.0) max: max_food update: food + food_prod;
    rgb color <- rgb(int(255 * (1 - food)), 255, int(255 * (1 - food))) update: rgb(int(255 * (1 - food)), 255, int(255 * (1 - food)));
//    list<vegetation_cell> neighbors2 <- (self neighbors_at 2);

    list<vegetation_cell> neighbors1 <- self neighbors_at 1;// return neighbors within 1 field
    list<vegetation_cell> neighbors2 <- self neighbors_at 2; // return neighbors within 2 fields
    list<vegetation_cell> neighbors3 <- self neighbors_at 3; // ...
    list<vegetation_cell> neighbors4 <- self neighbors_at 4;
    list<vegetation_cell> neighbors5 <- self neighbors_at 5;
    list<vegetation_cell> neighbors6 <- self neighbors_at 6;
}
