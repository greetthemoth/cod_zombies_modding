#include common_scripts\utility; 
#include maps\_utility;
#include maps\_zombiemode_utility;
interpolate(value, minimum, maximum){
   return (value - minimum) / (maximum - minimum);
}
pow(n, power){
	if(power == 0)
		return 1;
	for(i = 1; i < power; i++){
		n*=n;
	}
	return n;
}
define_or(s,or){
	if(IsDefined( s ))
		return s;
	return or;
}
clamp(n, min, max){
	return min(max,max(min,n));
}
