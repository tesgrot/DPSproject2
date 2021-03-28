/**
* Name: Prey (DPS Project 2 - Sheep vs. Wolves)
* Group: 3
* Group members:
* 	202001351 - Micha Heiß
* 	201902778 - Denis Hlinka
* 	201911250 - Tereza Madova
* 	201911260 - Mircea Melinte
* 	201910044 - Peter Miodrag Varanic
*/

model prey

import "prey_predator.gaml"
import "generic_species.gaml"

global {
	/* Prey info */
	int nb_preys_init <- 200;
    int nb_preys -> {length(prey)};
    float prey_max_energy <- 1.0;
    float prey_max_transfert <- 0.1;
    float prey_energy_consum <- 0.05;
    float prey_proba_reproduce <- 0.05;
    int prey_nb_max_offsprings <- 5;
    float prey_energy_reproduce <- 0.05;
    float prey_energy_graze <- 0.01;
    float prey_energy_wander <- 0.02;
}

species prey parent: generic_species {
	// Change color of animal based on energy level
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

	// has_mate function returns true if there is at least one other member of the same species within one cell
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
        float energy_transfert <- 0.0;
        if my_cell.food > 0 { // If current cell contains food
            energy_transfert <- min([max_transfert, my_cell.food]); // "Eat" as much food as possible
            my_cell.food <- my_cell.food - energy_transfert; // Update cell's food value (subtract eaten food)
        }             
        return energy_transfert;
    }

    vegetation_cell choose_cell {
    	vegetation_cell closest_predator <- one_of(my_cell.neighbors1 where !(empty(predator inside(each))));
    	if closest_predator != nil {
    		// If predator in neighboring cell, flee away to furthest possible field
    		energy_consum <- 3 * energy_wander;
    		return my_cell.neighbors3 with_max_of (each distance_to closest_predator);
    	} else {
    		// If no predator in neighboring cell, chech predators within vision (3 fields)
    		closest_predator <- one_of(my_cell.neighbors2 where !(empty(predator inside (each))));
    		if closest_predator = nil {
    			closest_predator <- one_of(my_cell.neighbors3 where !(empty(predator inside (each))));
    		}
    		if closest_predator != nil {
    			// If predator in sight, wander away
    			energy_consum <- energy_wander;
    			return my_cell.neighbors1 with_max_of(each distance_to closest_predator);
    		} else {
    			// No predator in sight
    			if energy > (energy_reproduce + energy_wander) {
    				// Enough energy to reproduce
    				vegetation_cell closest_prey <- one_of(my_cell.neighbors1 where !(empty(prey inside(each))));
    				if closest_prey = nil {
    					closest_prey <- one_of(my_cell.neighbors2 where !(empty(prey inside(each))));
    				}
    				if closest_prey = nil {
    					closest_prey <- one_of(my_cell.neighbors3 where !(empty(prey inside(each))));
    				}
    				if closest_prey != nil {
    					// Go towards other prey to mate
    					energy_consum <- energy_wander;
    					return my_cell.neighbors1 closest_to (closest_prey);
    				} else {
    					// No one in sight, go for food
    					// If enough food on current spot, graze
    					if my_cell.food > max_transfert {
    						energy_consum <- energy_graze;
    						return my_cell;
    					}
    					// Not enough food on current spot, wander to better spot
    					else {
    						energy_consum <- energy_wander;
    						return my_cell.neighbors1 with_max_of (each.food);
    					}
    				}
    			} else {
    				// Not enough energy to reproduce
    				// Go to greenest grass
    				energy_consum <- energy_wander;
    				return my_cell.neighbors1 with_max_of (each.food);
    			}
    		}
    	}
    	write "error no case matched. ";
        return my_cell.neighbors1 with_max_of (each.food);
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
