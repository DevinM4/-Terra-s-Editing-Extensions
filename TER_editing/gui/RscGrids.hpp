class TER_RscDisplayGrids
{
	idd = 73041;
	duration = 1e+6;
	fadeIn = 0;
	fadeOut = 0;
	ONLOAD(Grids)
	class controls 
	{
		class background : RscText
		{
			x = safeZoneXAbs;
			y = safeZoneY;
			w = safeZoneWAbs;
			h = safeZoneH;
			colorBackground[] = { 1,1,1,0.8 };
		};
		class absXT : RscText
		{
			x = 0;
			y = 0;
			w = 1;
			h = pixelH;
			colorBackground[] = { 0,1,0,0.5 };
		};
		class absXB : absXT
		{
			y = 1;
		};
		class absYL : absXT
		{
			w = pixelW;
			h = 1;
		};
		class absYR : absYL
		{
			x = 1;
		};
/*		class dead_top: RscText
		{
			x = safeZoneX;
			y = safeZoneY;
			w = safeZoneWAbs;
			h = 0 - safeZoneY;
			colorBackground[] = { 1,0,0,0.5 };
		};
		class dead_bottom: dead_top
		{
			y = 1;
			//h = safeZoneY + safeZoneH - 1;
		};
		class dead_left: dead_top
		{
			x = safeZoneX;
			y = 0;
			w = ;
			h = 1;
			
		class frame_absoluteBox : RscFrame
		{
			x = 0;
			y = 0;
			w = 1;
			h = 1;
			colorText[] = { 0,0,1,1 };
		};
*/
		class line_middleV: RscText
		{
			x = 0.5 - pixelW;
			y = safeZoneY;
			w = 2 * pixelW;
			h = safeZoneH;
			colorBackground[] = { 1,1,0,1 };
		};
		class line_middleH: RscText
		{
			x = safeZoneX;
			y = 0.5 - pixelH;
			w = safeZoneW;
			h = 2 * pixelh;
			colorBackground[] = { 1,1,0,1 };
		};
	};
};