/**
* Name: Predator (DPS Project 2 - Sheep vs. Wolves)
* Group: 3
* Group members:
* 	202001351 - Micha Heiß
* 	201902778 - Denis Hlinka
* 	201911250 - Tereza Madova
* 	201911260 - Mircea Melinte
* 	201910044 - Peter Miodrag Varanic
*/

model predator

import "prey_predator.gaml"
import "generic_species.gaml"

global {
	/* Predator info */
    int nb_predators_init <- 20;
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
}

species predator parent: generic_species {
	// Change color of animal based on energy level
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

	/* Reproduction behaviour
	 * flip(proba) returns bool val with certain probability
	 * has_mate function returns true if there is at least one other member of the same species within one cell
	 */
    reflex reproduce when: (energy >= energy_reproduce) and (flip(proba_reproduce) and has_mate()) {
        int nb_offsprings <- rnd(1, nb_max_offsprings);
        create species(self) number: nb_offsprings {
            my_cell <- myself.my_cell;
            location <- my_cell.location;
            energy <- myself.energy / nb_offsprings;
        }
        energy <- energy / nb_offsprings;
    }
    
    float energy_from_eat {
        list<prey> reachable_preys <- prey inside my_cell;
        // If there are any preys within the cell, kill one of them
        if(! empty(reachable_preys)) {
            ask one_of (reachable_preys) {
                do die;
            }
            // Return amount of energy obtained from eating prey
            return energy_transfert;
        }
        return 0.0;
    }

    vegetation_cell choose_cell {
        vegetation_cell my_cell_tmp <- one_of(my_cell.neighbors1 where !(empty(prey inside (each))));
        // If prey is one cell away, wander towards
        if my_cell_tmp != nil {
        	energy_consum <- energy_wander;
        	return my_cell_tmp;
        }
        // No prey within one cell away, check 2 cells
        my_cell_tmp <- one_of(my_cell.neighbors2 where !(empty(prey inside (each))));
        // If prey is two cells away, sprint towards
        if my_cell_tmp != nil {
        	energy_consum <- energy_sprint;
            return my_cell_tmp;
        }
    	// Check closest prey within furhter and further reach
		my_cell_tmp <- one_of(my_cell.neighbors3 where !(empty(prey inside (each))));
		if my_cell_tmp = nil {
			my_cell_tmp <- one_of(my_cell.neighbors4 where !(empty(prey inside (each))));
		}
		if my_cell_tmp = nil {
			my_cell_tmp <- one_of(my_cell.neighbors5 where !(empty(prey inside (each))));
		}
		if my_cell_tmp = nil {
			my_cell_tmp <- one_of(my_cell.neighbors6 where !(empty(prey inside (each))));
		}
		// If there was prey within 6 cells, sprint towards closest one
		if my_cell_tmp != nil {
    		energy_consum <- energy_sprint;
			return my_cell.neighbors2 closest_to my_cell_tmp;
		} else {
			// If enough energy to reproduce, move towards mate (if there are any)
			if energy > energy_reproduce {
				// Check other predators within the cell, if any, graze
				if length(predator inside my_cell) > 1 {
					energy_consum <- energy_graze;
					return my_cell;
				}
				vegetation_cell closest_predator <- one_of((my_cell.neighbors1) where !empty(predator inside each));
				if closest_predator != nil {
					energy_consum <- energy_wander;
					return closest_predator;
				}
				if closest_predator = nil {
					closest_predator <- one_of((my_cell.neighbors2) where !empty(predator inside each));
				}
				if closest_predator = nil {
					closest_predator <- one_of((my_cell.neighbors3) where !empty(predator inside each));
				}
				if closest_predator = nil {
					closest_predator <- one_of((my_cell.neighbors4) where !empty(predator inside each));
				}
				if closest_predator = nil {
					closest_predator <- one_of((my_cell.neighbors5) where !empty(predator inside each));
				}
				if closest_predator = nil {
					closest_predator <- one_of((my_cell.neighbors6) where !empty(predator inside each));
				}
				if closest_predator != nil {
					energy_consum <- energy_wander;
					return my_cell.neighbors1 closest_to closest_predator;
				}
			}
			// No prey to hunt nor predator to mate with within 6 cells vision
			// Wander towards / stay at greenest grass
			vegetation_cell greenest_grass <- my_cell.neighbors1 closest_to (my_cell.neighbors2 with_max_of (each.food));
			if my_cell.food >= greenest_grass.food {
				energy_consum <- energy_graze;
				return my_cell;	
			} else {
				energy_consum <- energy_wander;
				return greenest_grass;
			}
		}
    }
    
    bool has_mate {
		return length(species(self) inside my_cell) >= 2;
    }

    aspect base {
    	if has_mate() { // display multiple animals of the same species on one cell as darker square
    		draw square(size * 2) color: darkcolor;
    	} else { // display animal as circle
    		draw circle(size) color: color;
    	}
    }
}
