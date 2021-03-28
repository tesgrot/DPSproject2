/**
* Name: Prey-Predator (DPS Project 2 - Sheep vs. Wolves)
* Group: 3
* Group members:
* 	202001351 - Micha Heiß
* 	201902778 - Denis Hlinka
* 	201911250 - Tereza Madova
* 	201911260 - Mircea Melinte
* 	201910044 - Peter Miodrag Varanic
*/

model prey_predator

import "prey.gaml"
import "predator.gaml"

global {
	/* Other info */
    file map_init <- image_file("../includes/data/raster_map.png");

    init {
        create prey number: nb_preys_init;
        create predator number: nb_predators_init;
        ask vegetation_cell { // Initialize colors of cells by raster_map
            color <- rgb (map_init at {grid_x,grid_y}); // Color taken from raster_map for each cell
            food <- 1 - (((color as list) at 0) / 255); // Value of food offered by cell - assigned from initial color intensity
            food_prod <- food / 100; // How much grass can grow on each cell as time passes (initial "juicy" spots grow grass faster)
        }
    }
    
    reflex stop_simulation when: (nb_preys = 0) or (nb_predators = 0) {
        do pause;
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
