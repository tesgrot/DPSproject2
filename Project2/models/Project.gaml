/**
* Name: Project
* Based on the internal skeleton template. 
* Author: terezamadova
* Tags: 
*/

model Project

global {
	/* Prey info */
    int nb_preys_init <- 200;//200;
    int nb_preys -> {length(prey)};
    float prey_max_energy <- 1.0;
    float prey_max_transfert <- 0.1;
    float prey_energy_consum <- 0.05;
    float prey_proba_reproduce <- 0.05;
    int prey_nb_max_offsprings <- 5;
    float prey_energy_reproduce <- 0.05;
    float prey_energy_graze <- 0.01;
    float prey_energy_wander <- 0.02;
    
	/* Predator info */
    int nb_predators_init <- 1;//20;
    int nb_predators -> {length(predator)};
    float predator_max_energy <- 1.0;
    float predator_energy_transfert <- 0.5;
    float predator_energy_consum <- 0.02;
    float predator_proba_reproduce <- 0.01;
    int predator_nb_max_offsprings <- 3;
    float predator_energy_reproduce <- 0.05;
    float predator_energy_graze <- 0.01;
    float predator_energy_wander <- 0.02;
    float predator_energy_sprint <- 0.025;
    
	/* Other info */
    file map_init <- image_file("../includes/data/raster_map.png");
    bool is_batch <- false;

    init {
        create prey number: nb_preys_init;
        create predator number: nb_predators_init;
        ask vegetation_cell { // initialize colors of cells by raster_map
            color <- rgb (map_init at {grid_x,grid_y}); // color taken from raster_map for each cell
            food <- 1 - (((color as list) at 0) / 255); // value of food offered by cell - assigned from initial color intensity
            food_prod <- food / 100; // how much grass can grow on each cell as time passes (initial "juicy" spots grow grass faster)
        }
    }
    
    /* Pause simulation once some species extincts */
    reflex stop_simulation when: ((nb_preys = 0) or (nb_predators = 0)) and !is_batch {
        do pause;
    } 
}

species generic_species {
    float size <- 1.0;
    rgb color;
    rgb darkcolor;
    float max_energy;
    float max_transfert;
    float energy_consum;
    float proba_reproduce;
    int nb_max_offsprings;
    float energy_reproduce;
    float energy_sprint; 
    float energy_wander;
    vegetation_cell my_cell <- one_of(vegetation_cell); // place at random cell
    float energy <- rnd(max_energy) update: energy - energy_consum max: max_energy; // initiate random energy (at most max_energy), subtract certain energy at each step

    init {
        location <- my_cell.location;
    }

    reflex basic_move {
        my_cell <- choose_cell();
        location <- my_cell.location;
    }

    reflex eat {
        energy <- energy + energy_from_eat(); // add energy from eating    
    }

    reflex die when: energy <= 0 {
        do die;
    }

	/* Reproduction behaviour
	 * flip(proba) returns bool val with certain probability
	 * has_mate function returns true if there is at least one other member of the same species within one cell
	 */
    reflex reproduce when: (energy >= energy_reproduce) and (flip(proba_reproduce) and has_mate()) {
        int nb_offsprings <- rnd(1, nb_max_offsprings); // returns random number between 1 and no. of max offsprings
        create species(self) number: nb_offsprings {
        	write "reproduce " + self;
            my_cell <- myself.my_cell;
            location <- my_cell.location;
            energy <- myself.energy / nb_offsprings; // assign offsprings parts of "parent's" energy 
        }
        energy <- energy / nb_offsprings; // adjust energy
    }

    float energy_from_eat {
        return 0.0;
    }
    
    vegetation_cell move_distance (vegetation_cell closestPrey, float moves, bool towards) {
    	
		float preyX <- closestPrey.location.x;
		float preyY <- closestPrey.location.y;
		float selfX <- self.my_cell.location.x;
		float selfY <- self.my_cell.location.y;
		float x_diff <- preyX-selfX;
		float y_diff <- preyY-selfY;
		float moveX <- 0.0;
		float moveY <- 0.0;
		int newX <- 0;
		int newY <- 0;
		float moveattr <- moves;
		
		write "moves left: " + moves;
		/* Movement version 1 */
		// if self right of prey
		if (selfX > preyX) {
			// move left
			moveX <- - min([abs(x_diff), moves]);
			moves <- moves - min([abs(x_diff), moves]);
		} else 
		// self left of prey
		if (selfX < preyX) {
			// move right
			moveX <- min([abs(x_diff), moves]);
			moves <- moves - min([abs(x_diff), moves]);
		} else {
			// if self under prey
			if (selfY > preyY) {
				// move up
				moveY <- -min([abs(y_diff), moves]);
				moves <- moves - min([abs(y_diff), moves]);
				
			} else
			// if self above prey
			if(selfY < preyY) {
				// move down
				moveY <- min([abs(y_diff), moves]);
				moves <- moves - min([abs(y_diff), moves]);
			}
		}
		/* Movement version 1 END */
		
	
		/* Movement version 2 */
//		// movement x
//		moveX <- min([abs(x_diff), moves]); // move on x_axis as much as is the difference between prey & predator, at most 2
//		moves <- moves - moveX;
//		if (x_diff < 0) { // if prey was on the left, move to left
//			moveX <- moveX * (-1);
//		}
//		
//		// move y if there is more moves
//		if (moves > 0) {
//			moveY <- min([abs(y_diff), moves]);
//			moves <- moves - moveY;
//			if (y_diff < 0) {
//				moveY <- moveY * (-1);
//			}
//		}
		/* Movement version 2 END */
		
		write species(self);
		write "moves left: " + moves;
		if(species(self) = prey){
			write "xdsiff: "+x_diff;
			write "ydiff: "+y_diff;
//			write "I'm prey and lost energy.";
			float temp <- energy;
			energy <- energy - energy_wander*(moveattr-moves);

			write "lost energy: " + (temp-energy);

		} else { // if(species(self) is species(predator))
			write "wolf loses energy: ";
			if (moves = 0) {
//				write "before: " + energy;
				energy <- energy - energy_sprint; // subtract energy from sprinting
//				write "now: " + energy;
			} else if (moves = 1) {
				energy <- energy - energy_wander; // subtract energy from wandering
			}
		}
		
		write "*selfXY: " + selfX + " " + selfY;
		write "*moveXY: " + moveX + " " + moveY; 
		write "*sefl+moveXY: " + (selfX + moveX) + " " + (selfY + moveY);
		
		if(towards){
			newX <- selfX + moveX;
			newY <- selfY + moveY;
		} else {
			newX <- selfX - moveX;
			newY <- selfY - moveY;
		}
		return vegetation_cell at {newX, newY};
    }

    vegetation_cell choose_cell {
        return nil;
    }
    
    bool has_mate { // returns true if other member of species group is within the cell
    	if (length(species(self) inside (my_cell)) >= 2) {
			return true;
		}
		return false;
    }

    aspect base {
    	if (has_mate()) {
    		draw square(size*2) color: darkcolor;
    	} else {
    		draw circle(size) color: color;
    	}
    }
}

species prey parent: generic_species {
	rgb color <- rgb(int(150 * (1-energy)), int(150 * (1-energy)), 255)
		update: rgb(int(150 * (1-energy)), int(150 * (1-energy)), 255);
	rgb darkcolor <- #darkblue;
    float max_energy <- prey_max_energy;
    float max_transfert <- prey_max_transfert;
    float energy_consum <- prey_energy_consum;
    float proba_reproduce <- prey_proba_reproduce;
    int nb_max_offsprings <- prey_nb_max_offsprings;
    float energy_reproduce <- prey_energy_reproduce;
    float energy_graze <- prey_energy_graze;
    float energy_wander <- prey_energy_wander;

    float energy_from_eat {
        float energy_transfert <- 0.0;
        if(my_cell.food > 0) {
            energy_transfert <- min([max_transfert, my_cell.food]);
            my_cell.food <- my_cell.food - energy_transfert;
        }             
        return energy_transfert;
    }

    vegetation_cell choose_cell { // strategy of movement (sheep go after juiciest grass within 1 field)
		vegetation_cell orig_cell <- my_cell;
		vegetation_cell targ_cell <- my_cell;
		
		list<predator> predators <- (predator at_distance 3); // list of "visible" predators
		// If predator is at neighboring cell, flee
		predator closestPredator <- (predator at_distance 3) closest_to(self); //closest predator within the sight of prey
		if (closestPredator != nil) {
			if (self.location distance_to closestPredator.location <= 1) { // if there is predator within 1 cell, flee
				// move away by 3 fields (-energy_flee)
				targ_cell <- move_distance(closestPredator.my_cell, 3.0, false);
			} else { // Otherwise move slowly away
				// move away by 1 field (-energy_wander)
				targ_cell <- move_distance(closestPredator.my_cell, 1.0, false);
			}
		} else { // If there aren't any predators nearby
			//TODO: if enought energy to mate...
			vegetation_cell greener_neighbor <- orig_cell.neighbors1 with_max_of (each.food);
			write "greener neighbors has food: "+ greener_neighbor.food; 
			write "I have food: " + orig_cell.food;
    		if (orig_cell.food < greener_neighbor.food) { // if current cell has less food than greenest neighbor
    			//move towards greener neighbor by 1 cell 
    			targ_cell <- move_distance(greener_neighbor, 1.0, true);
    			write "!!!moved to greener neigbor";
    		} else { // stay at the same cell
    			targ_cell <- orig_cell;
    			write "did not move";
    			energy <- energy - energy_graze; // subtract energy from grazing
    		}
		}
		write orig_cell;
		write targ_cell;
		my_cell <- targ_cell;
        return targ_cell;
    }
}

species predator parent: generic_species {
	rgb color <- rgb(255, int(150 * (1-energy)), int(150 * (1-energy)))
		update: rgb(255, int(150 * (1-energy)), int(150 * (1-energy)));
	rgb darkcolor <- #crimson;
    float max_energy <- predator_max_energy;
    float energy_transfert <- predator_energy_transfert;
    float energy_consum <- predator_energy_consum;
    float proba_reproduce <- predator_proba_reproduce;
    int nb_max_offsprings <- predator_nb_max_offsprings;
    float energy_reproduce <- predator_energy_reproduce;
    float energy_graze <- predator_energy_graze;
    float energy_wander <- predator_energy_wander;
    float energy_sprint <- predator_energy_sprint;

    float energy_from_eat {
        list<prey> reachable_preys <- prey inside (my_cell); // list of all preys within the cell
        if(! empty(reachable_preys)) { // if there are any
            ask one_of (reachable_preys) { // kill prey
                do die;
            }
            return energy_transfert; // return amount of preset energy obtained from eating prey
        }
        return 0.0;
    }
    
    vegetation_cell choose_cell {
    	vegetation_cell orig_cell <- self.my_cell;
    	vegetation_cell targ_cell <- self.my_cell;
    	write "orig_cell:"+orig_cell;
    	
    	prey closestPrey <- (prey at_distance 6) closest_to(self); //closest prey within the sight of predator
    	
    	if (closestPrey != nil) { // if there is any
			targ_cell <- move_distance(closestPrey.my_cell, 2.0, true);
    	} else { // otherwise move towards greener grass as that's where sheep would go as well
    		vegetation_cell greener_grass <- orig_cell.neighbors2 with_max_of (each.food);
    		write "greener_grass" + greener_grass;
    		targ_cell <- move_distance(greener_grass, 1.0, true);
    		write "targ_cell:"+targ_cell;
    		if (orig_cell.food >= targ_cell.food) { // unless current cell is just as "green"
    			targ_cell <- orig_cell;
    			energy <- energy - energy_graze; // subtract energy from grazing
    		}
    	}
		my_cell <- targ_cell;
		return targ_cell;
    }
}

grid vegetation_cell width: 50 height: 50 neighbors: 4 {
    float max_food <- 1.0;
    float food_prod <- rnd(0.01);
    float food <- rnd(1.0) max: max_food update: food + food_prod; // "growing grass"
    rgb color <- rgb(int(255 * (1 - food)), 255, int(255 * (1 - food))) update: rgb(int(255 * (1 - food)), 255, int(255 * (1 - food)));
    list<vegetation_cell> neighbors2 <- self neighbors_at 2;// return neighbors within 2 fields
    list<vegetation_cell> neighbors1 <- self neighbors_at 1; // return neighbors within 1 field
}

experiment prey_predator type: gui {
    parameter "Initial number of preys: " var: nb_preys_init min: 0 max: 1000 category: "Prey";
    parameter "Prey max energy: " var: prey_max_energy category: "Prey";
    parameter "Prey max transfert: " var: prey_max_transfert category: "Prey";
    parameter "Prey energy consumption: " var: prey_energy_consum category: "Prey";
    parameter "Initial number of predators: " var: nb_predators_init min: 0 max: 200 category: "Predator";
    parameter "Predator max energy: " var: predator_max_energy category: "Predator";
    parameter "Predator energy transfert: " var: predator_energy_transfert category: "Predator";
    parameter "Predator energy consumption: " var: predator_energy_consum category: "Predator";
    parameter 'Prey probability reproduce: ' var: prey_proba_reproduce category: 'Prey';
    parameter 'Prey nb max offsprings: ' var: prey_nb_max_offsprings category: 'Prey';
    parameter 'Prey energy reproduce: ' var: prey_energy_reproduce category: 'Prey';
    parameter 'Predator probability reproduce: ' var: predator_proba_reproduce category: 'Predator';
    parameter 'Predator nb max offsprings: ' var: predator_nb_max_offsprings category: 'Predator';
    parameter 'Predator energy reproduce: ' var: predator_energy_reproduce category: 'Predator';

    output {
        display main_display {
            grid vegetation_cell lines: #black;
            species prey aspect: base;
            species predator aspect: base;
        }

//        display Population_information refresh: every(5#cycles) {
//            chart "Species evolution" type: series size: {1,0.5} position: {0, 0} {
//                data "number_of_preys" value: nb_preys color: #blue;
//                data "number_of_predator" value: nb_predators color: #red;
//            }
//            chart "Prey Energy Distribution" type: histogram background: #lightgray size: {0.5,0.5} position: {0, 0.5} {
//                data "]0;0.25]" value: prey count (each.energy <= 0.25) color:#blue;
//                data "]0.25;0.5]" value: prey count ((each.energy > 0.25) and (each.energy <= 0.5)) color:#blue;
//                data "]0.5;0.75]" value: prey count ((each.energy > 0.5) and (each.energy <= 0.75)) color:#blue;
//                data "]0.75;1]" value: prey count (each.energy > 0.75) color:#blue;
//            }
//            chart "Predator Energy Distribution" type: histogram background: #lightgray size: {0.5,0.5} position: {0.5, 0.5} {
//                data "]0;0.25]" value: predator count (each.energy <= 0.25) color: #red;
//                data "]0.25;0.5]" value: predator count ((each.energy > 0.25) and (each.energy <= 0.5)) color: #red;
//                data "]0.5;0.75]" value: predator count ((each.energy > 0.5) and (each.energy <= 0.75)) color: #red;
//                data "]0.75;1]" value: predator count (each.energy > 0.75) color: #red;
//            }
//        }

        monitor "Number of preys" value: nb_preys;
        monitor "Number of predators" value: nb_predators;
    }
}

experiment Optimization type: batch repeat: 2 keep_seed: true until: ( time > 200 ) {
    parameter "Prey max transfert:" var: prey_max_transfert min: 0.05 max: 0.5 step: 0.05;
    parameter "Prey energy reproduce:" var: prey_energy_reproduce min: 0.05 max: 0.75 step: 0.05;
    parameter "Predator energy transfert:" var: predator_energy_transfert min: 0.1 max: 1.0 step: 0.1;
    parameter "Predator energy reproduce:" var: predator_energy_reproduce min: 0.1 max: 1.0 step: 0.1;
    parameter "Batch mode:" var: is_batch <- true;
    
    method tabu maximize: nb_preys + nb_predators iter_max: 10 tabu_list_size: 3;
}