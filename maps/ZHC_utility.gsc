#include common_scripts\utility; 
#include maps\_utility;
#include maps\_zombiemode_utility;
interpolate(value, minimum, maximum){
   return (value - minimum) / (maximum - minimum);
}
pow(n, power){
	for(i = 0; i < power; i++){
		n*=n;
	}
	return n;
}
