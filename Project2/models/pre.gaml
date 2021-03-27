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
    int nb_predators_init <- 20;//20;
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
        ask vegetation_cell {
            color <-  rgb(map_init at {grid_x,grid_y});
            food <- 1 - (((color as list) at 0) / 255);
            food_prod <- food / 100; 
        }
    }
    
    /* Not necessary to save any data */
//    reflex save_result when: (nb_preys > 0) and (nb_predators > 0){
//        save ("cycle: "+ cycle + "; nbPreys: " + nb_preys
//            + "; minEnergyPreys: " + (prey min_of each.energy)
//            + "; maxSizePreys: " + (prey max_of each.energy) 
//               + "; nbPredators: " + nb_predators           
//               + "; minEnergyPredators: " + (predator min_of each.energy)          
//               + "; maxSizePredators: " + (predator max_of each.energy)) 
//               to: "results.txt" type: "text" rewrite: (cycle = 0) ? true : false;
//    }
    
    reflex stop_simulation when: (nb_preys = 0) or (nb_predators = 0) {
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
    //image_file my_icon;
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
        energy <- energy + energy_from_eat();        
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
            my_cell <- myself.my_cell;
            location <- my_cell.location;
            energy <- myself.energy / nb_offsprings;
        }

        energy <- energy / nb_offsprings;
    }

    float energy_from_eat {
        return 0.0;
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
//    rgb color <- #blue;
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
    //image_file my_icon <- image_file("../includes/data/sheep.png");

    float energy_from_eat {
        float energy_transfert <- 0.0;
        if(my_cell.food > 0) { // if current cell contains food
            energy_transfert <- min([max_transfert, my_cell.food]); // "eat" as much food as possible
            my_cell.food <- my_cell.food - energy_transfert; // update cell's food value (subtract eaten food)
        }             
        return energy_transfert;
    }

    vegetation_cell choose_cell {
    	vegetation_cell closest_predator <- (my_cell.neighbors1) first_with (!(empty(predator inside(each))));
    	if closest_predator != nil {
    		// if predator next to me sprint away to furthest possible field
    		write "sprint away 3";
    		energy_consum <- energy_sprint;
    		return (my_cell.neighbors3) with_max_of (each distance_to closest_predator);
    	}else{
    		// if no predator next to me
    		// walk away from predators within vision (3 fields)
    		closest_predator <- (my_cell.neighbors3) first_with (!(empty(predator inside (each))));
    		if closest_predator != nil {
    			// if predator in sight, walk away
    			write "walk away 1";
    			energy_consum <- energy_wander;
    			return (my_cell.neighbors1) with_max_of(each distance_to closest_predator);
    		}else{
    			// no predator in sight
    			if energy > energy_reproduce {
    				// enough energy to reproduce
    				write "enough energy to reproduce";
    				vegetation_cell closest_prey <- (my_cell.neighbors1) first_with (!(empty(prey inside(each))));
    				if closest_prey = nil {
    					closest_prey <- (my_cell.neighbors2) first_with (!(empty(prey inside(each))));
    				}
    				if closest_prey = nil {
    					closest_prey <- (my_cell.neighbors3) first_with (!(empty(prey inside(each))));
    				}
    				if closest_prey != nil {
    					// go towards other prey to mate
    					write "walk towards mate";
    					energy_consum <- energy_wander;
    					return (my_cell.neighbors1) with_max_of(each distance_to closest_prey);
    				}else{
    					// no one in sight, go for food
    					write "no one in sight, go for food";
    					energy_consum <- energy_wander;
    					return (my_cell.neighbors1) with_max_of (each.food);
    				}
    			}else{
    				// not enough energy to reproduce
    				// go to greenest grass
    				write "not enough energy, go towards food";
    				energy_consum <- energy_wander;
    				return (my_cell.neighbors1) with_max_of (each.food);
    			}
    		}
    	}
    	write "error no case matched. ";
    	
        return (my_cell.neighbors2) with_max_of (each.food);
    }
}

species predator parent: generic_species {
//    rgb color <- #red;
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
    //image_file my_icon <- image_file("../includes/data/wolf.png");

    float energy_from_eat {
        list<prey> reachable_preys <- prey inside (my_cell); // list of all preys within the cell
        if(! empty(reachable_preys)) { // if there are any
            ask one_of (reachable_preys) { // kill prey
//            	write "kill";
                do die;
            }
            return energy_transfert; // return amount of preset energy obtained from eating prey
        }
        return 0.0;
    }

    vegetation_cell choose_cell {
        vegetation_cell my_cell_tmp <- (my_cell.neighbors1) first_with (!(empty(prey inside (each))));
        if my_cell_tmp = nil {
        	my_cell_tmp <- (my_cell.neighbors2) first_with (!(empty(prey inside (each))));
        }
        if my_cell_tmp != nil {
        	energy_consum <- energy_sprint;
            return my_cell_tmp;
        } else {
        	// no prey in sight
        	// if prey within 6 tiles go towards them
        	energy_consum <- energy_wander;
			my_cell_tmp <- my_cell.neighbors2 closest_to (my_cell.neighbors1 first_with(!(empty(prey inside (each)))));
			if my_cell_tmp = nil {
				my_cell_tmp <- my_cell.neighbors2 closest_to (my_cell.neighbors2 first_with(!(empty(prey inside (each)))));
			}
			if my_cell_tmp = nil {
				my_cell_tmp <- my_cell.neighbors2 closest_to (my_cell.neighbors3 first_with(!(empty(prey inside (each)))));
			}
			if my_cell_tmp = nil {
				my_cell_tmp <- my_cell.neighbors2 closest_to (my_cell.neighbors4 first_with(!(empty(prey inside (each)))));
			}
			if my_cell_tmp = nil {
				my_cell_tmp <- my_cell.neighbors2 closest_to (my_cell.neighbors5 first_with(!(empty(prey inside (each)))));
			}
			if my_cell_tmp = nil {
				my_cell_tmp <- my_cell.neighbors2 closest_to (my_cell.neighbors6 first_with(!(empty(prey inside (each)))));
			}
			if my_cell_tmp != nil {
				return my_cell_tmp;
			}else{
				// also no prey in further vision
				// go to greenest gras
				return (my_cell.neighbors2) with_max_of (each.food);
			}
        }
    }
}

grid vegetation_cell width: 50 height: 50 neighbors: 4 {
    float max_food <- 1.0;
    float food_prod <- rnd(0.01);
    float food <- rnd(1.0) max: max_food update: food + food_prod; // "growing grass"
    rgb color <- rgb(int(255 * (1 - food)), 255, int(255 * (1 - food))) update: rgb(int(255 * (1 - food)), 255, int(255 * (1 - food)));
    list<vegetation_cell> neighbors1 <- self neighbors_at 1;// return neighbors within 2 fields
    list<vegetation_cell> neighbors2 <- self neighbors_at 2; // return neighbors within 1 field
    list<vegetation_cell> neighbors3 <- self neighbors_at 3;
    list<vegetation_cell> neighbors4 <- self neighbors_at 4;
    list<vegetation_cell> neighbors5 <- self neighbors_at 5;
    list<vegetation_cell> neighbors6 <- self neighbors_at 6;
    float getDistance(vegetation_cell other) {
    	
    	return 0;
    }
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

//        display info_display {
//            grid vegetation_cell lines: #black;
//            species prey aspect: info;
//            species predator aspect: info;
//        }

        display Population_information refresh: every(5#cycles) {
            chart "Species evolution" type: series size: {1,0.5} position: {0, 0} {
                data "number_of_preys" value: nb_preys color: #blue;
                data "number_of_predator" value: nb_predators color: #red;
            }
            chart "Prey Energy Distribution" type: histogram background: #lightgray size: {0.5,0.5} position: {0, 0.5} {
                data "]0;0.25]" value: prey count (each.energy <= 0.25) color:#blue;
                data "]0.25;0.5]" value: prey count ((each.energy > 0.25) and (each.energy <= 0.5)) color:#blue;
                data "]0.5;0.75]" value: prey count ((each.energy > 0.5) and (each.energy <= 0.75)) color:#blue;
                data "]0.75;1]" value: prey count (each.energy > 0.75) color:#blue;
            }
            chart "Predator Energy Distribution" type: histogram background: #lightgray size: {0.5,0.5} position: {0.5, 0.5} {
                data "]0;0.25]" value: predator count (each.energy <= 0.25) color: #red;
                data "]0.25;0.5]" value: predator count ((each.energy > 0.25) and (each.energy <= 0.5)) color: #red;
                data "]0.5;0.75]" value: predator count ((each.energy > 0.5) and (each.energy <= 0.75)) color: #red;
                data "]0.75;1]" value: predator count (each.energy > 0.75) color: #red;
            }
        }

        monitor "Number of preys" value: nb_preys;
        monitor "Number of predators" value: nb_predators;
    }
}
