#include "..\ctrls.inc"
params ["_mode"];
/////////////////////////////
if (_mode == 1) then {// LOAD
/////////////////////////////
if (DEBUG_PAGE_1 getVariable ["pageInitialized",false]) exitWith {};
DEBUG_PAGE_1 setVariable ["pageInitialized",true];
//// LIVE DEBUG
BTN_LIVEDEBUG ctrlAddEventHandler ["ButtonClick",{
	disableSerialization;
	params ["_control","_state"];
	_fncWatchLoop = {
		params ["_inctrl"];
		_outCtrl = LIVE_WATCH((ctrlIDC _inctrl)+1);
		_startCommand = ctrlText _inctrl;
		while {_startCommand == ctrlText _inctrl} do {
			if (_startCommand == "") exitWith {_outCtrl ctrlSetText ""};
			if (isNil compile _startCommand) then {
				_outCtrl ctrlSetText "#NIL";
			} else {
				_result = [] call compile _startCommand;
				//if (isNil {_result}) exitWith {_outCtrl ctrlSetText ""};
				_outCtrl ctrlSetText str _result;
			};
			_curFrame = diag_frameno;
			waitUntil {diag_frameno != _curFrame};
		};
	};
	_state = isNull LIVE_DISPLAY;
	_ctrlIDCArray = [[7301,12285], [7303,12287], [7305,12289], [7307,12291]];
	_textChanged = {
		if (ctrlText LIVE_WATCH((_x select 0)) != ctrlText ESC_CTRL((_x select 1))) exitWith {true};
		false
	} forEach _ctrlIDCArray;
	if (_state OR _textChanged) then {
		if (_state) then {
			("TER_3den_RscWatchLive_layer" call BIS_fnc_rscLayer) cutRsc ["TER_3den_RscLiveWatch","PLAIN"];
		};
		{
			_escInCommand = ctrlText ESC_CTRL((_x select 1));
			if (_escInCommand != ctrlText LIVE_WATCH((_x select 0))) then {
				LIVE_WATCH((_x select 0)) ctrlSetText _escInCommand;
				[LIVE_WATCH((_x select 0))] spawn _fncWatchLoop;
			};
		} forEach _ctrlIDCArray;
	} else {
		("TER_3den_RscWatchLive_layer" call BIS_fnc_rscLayer) cutRsc ["default","PLAIN"];
	};
}];
//// PLAYER SIDE
_lbSideplayer = COMBO_SIDEPLAYER;
_sideArray = ["west","east","independent","civilian"];
_sideSystemArray = _sideArray apply {call compile _x};
{
	_lbSideplayer lbAdd _x;
} forEach _sideArray;
_lbSideplayer lbSetCurSel (_sideSystemArray find (side group player));
_lbSideplayer ctrlAddEventHandler ["LBSelChanged",{
	params ["_ctrl","_index"];
	_selectedSide = call compile (_ctrl lbText _index);
	if (_selectedSide == side player) exitWith {};
	_sideGroup = createGroup _selectedSide;
	[player] joinSilent _sideGroup;
}];
//// TELEPORT
//--TODO: Add indicator to the rscgrid with pos and distance and 3dicon?
_cbTeleport = CB_TELEPORT;
if (!isNil {missionNamespace getVariable "TER_3den_teleportEH"}) then {
	_cbTeleport cbSetChecked true;
};

_cbTeleport ctrlAddEventHandler ["CheckedChanged",{
	params ["_control","_state"];
	if (_state == 1) then {
		_displayEH = (findDisplay 46) displayAddEventHandler ["KeyDown",{
			params ["_display","_key","_shift","_ctrl","_alt"];
			if (_key == 0x14 && _shift) then {
				_aimPos = [getPos cursorObject,screenToWorld [0.5,0.5]] select (isNull cursorObject);
				player setPos _aimPos;
			};
		}];
		missionNamespace setVariable ["TER_3den_teleportEH",_displayEH];
	} else {
		_displayEH = missionNamespace getVariable ["TER_3den_teleportEH",-1];
		(findDisplay 46) displayRemoveEventHandler ["KeyDown",_displayEH];
		missionNamespace setVariable ["TER_3den_teleportEH",nil];
	};
}];
//// UNIT ICONS
_cbUnitIcons = CB_UNITICONS;
if ((missionNamespace getVariable ["TER_3den_unitIcons3DMEH",-1]) != -1) then {
	_cbUnitIcons cbSetChecked true;
};

_cbUnitIcons ctrlAddEventHandler ["CheckedChanged",{
	params ["_checkbox","_state"];
	if (_state == 1) then {
		// draw icons
		_3dMEH = addMissionEventHandler ["Draw3D",{
			{
				_bbr = boundingBoxReal _x;
				_bbr deleteAt 2;
				_bbr = _bbr apply {_x apply {abs _x}};
				_absBBR = (_bbr select 0) vectorAdd (_bbr select 1);
				_center = [0,0,(_absBBR select 2)*1.2];
				_center = _x modelToWorld _center;
				_text = [typeOf _x, str _x] select (vehicleVarName _x != "");
				_color = switch (side _x) do {
					case west: { [0,0.3,0.6] };
					case east: { [0.5,0,0] };
					case independent: { [0,0.5,0] };
					case civilian: { [0.4,0,0.5] };
					default { [0.7,0.6,0] };
				};
				_alpha = linearConversion [1000,0,player distance _x,0,1];
				_color pushBack _alpha;
				drawIcon3D ["",_color,_center,0.5,0.5,0,_text];
			} forEach (allUnits +vehicles);
		}];
		missionNamespace setVariable ["TER_3den_unitIcons3DMEH",_3dMEH];
	} else {
		_3dMEH = missionNamespace getVariable ["TER_3den_unitIcons3DMEH",-1];
		removeMissionEventHandler ["Draw3D",_3dMEH];
		missionNamespace setVariable ["TER_3den_unitIcons3DMEH",nil];
	};
}];

//// GRIDS
_cbDrawGrids = CB_GRIDS;
if (!isNull (uiNamespace getVariable ["TER_3den_RscGrids_display",displayNull])) then {
	_cbDrawGrids cbSetChecked true;
};

_cbDrawGrids ctrlAddEventHandler ["CheckedChanged",{
	params ["_ctrl","_state"];
	if (_state == 1) then {
		("TER_3den_RscGrids_layer" call BIS_fnc_rscLayer) cutRsc ["TER_RscDisplayGrids", "PLAIN"];
	} else {
		("TER_3den_RscGrids_layer" call BIS_fnc_rscLayer) cutRsc ["default", "PLAIN"];
	};
}];

//// UI GRID
_ind = COMBO_GUIGRID lbAdd "---Default---";
COMBO_GUIGRID lbSetData [_ind,str []];
COMBO_GUIGRID lbSetTooltip [_ind,"Use default GUI Editor settings (broken)"];

_ind = COMBO_GUIGRID lbAdd "GUI_GRID";
_guigridArray = [
	[
		"safezoneX",
		"safezoneY + safezoneH - (((safezoneW / safezoneH) min 1.2) / 1.2)",
		"(safezoneW / safezoneH) min 1.2",
		"((safezoneW / safezoneH) min 1.2) / 1.2"
	],
	"((safezoneW / safezoneH) min 1.2) / 40",
	"(((safezoneW / safezoneH) min 1.2) / 1.2) / 25",
	"GUI_GRID"
];
COMBO_GUIGRID lbSetData [_ind,str _guigridArray];
COMBO_GUIGRID lbSetTooltip [_ind,"GUI_GRID: Based upon safeZone values"];

_ind = COMBO_GUIGRID lbAdd "GUI_GRID, Centered";
_cguigridArray = [
	[
		"0.5",
		"0.5",
		"(safezoneW / safezoneH) min 1.2",
		"((safezoneW / safezoneH) min 1.2) / 1.2"
	],
	"((safezoneW / safezoneH) min 1.2) / 40",
	"(((safezoneW / safezoneH) min 1.2) / 1.2) / 25",
	"CGUI_GRID"
];
COMBO_GUIGRID lbSetData [_ind,str _cguigridArray];
COMBO_GUIGRID lbSetTooltip [_ind,"CGUI_GRID: Based upon safeZone values and centered in the middle of the screen"];

_uigridArray = [
	["safezoneX","safezoneY","safezoneW","safeZoneH"],
	"5 * 0.5 * pixelW * pixelGrid",
	"5 * 0.5 * pixelH * pixelGrid",
	"UI_GRID"
];
// make default
if (isNil {uiNamespace getVariable "TER_3den_GUIGrid"}) then {
	uiNamespace setVariable ["TER_3den_GUIGrid", _uigridArray];
};
_ind = COMBO_GUIGRID lbAdd "UI_GRID";
COMBO_GUIGRID lbSetData [_ind,str _uigridArray];
COMBO_GUIGRID lbSetTooltip [_ind,"UI_GRID: Based upon pixelGrid values"];

_uigridCenteredArray = [
	["0.5","0.5","safezoneW","safeZoneH"],
	"5 * 0.5 * pixelW * pixelGrid",
	"5 * 0.5 * pixelH * pixelGrid",
	"CUI_GRID"
];
_ind = COMBO_GUIGRID lbAdd "UI_GRID Centered";
COMBO_GUIGRID lbSetData [_ind,str _uigridCenteredArray];
COMBO_GUIGRID lbSetTooltip [_ind,"CUI_GRID: Based upon pixelGrid values, centered in the middle of the screen"];

COMBO_GUIGRID ctrlAddEventHandler ["LBSelChanged",{
	params ["_combo","_ind"];
	_data = call compile (_combo lbData _ind);
	uiNamespace setVariable ["TER_3den_GUIGrid", _data];
}];

_curGridVar = uiNamespace getVariable ["TER_3den_GUIGrid",[]];
_curGridInd = [[],_guigridArray,_cguigridArray,_uigridArray,_uigridCenteredArray] find _curGridVar;
COMBO_GUIGRID lbSetCurSel _curGridInd;

// handle drawing in GUI Editor
CB_GRIDSGUIEDITOR ctrlSetTooltip "Draw the grid upon opening the GUI Editor (recommended)";
CB_GRIDSGUIEDITOR ctrlAddEventHandler ["CheckedChanged",{
	params ["_control","_checked"];
	uiNamespace setVariable ["TER_3den_drawGridGUIEditor",_checked == 1];
}];
if (uiNamespace getVariable ["TER_3den_drawGridGUIEditor",true]) then {
	CB_GRIDSGUIEDITOR cbSetChecked true;
};

if (isClass (configfile >> "CfgPatches" >> "TER_guigridfix")) then {
	COMBO_GUIGRID ctrlEnable false;
	COMBO_GUIGRID ctrlSetTooltip "Not compatible with @GUI_GRID Fix";
}; // disable if the gui editor is already overwritten with the GUI_GRID fix

//// SWITCH UNIT
if (isMultiplayer) then {
	BTN_SWITCHUNIT ctrlSetTooltip "WARNING: Switching the unit in MP will have serious consequences for the functionality of the mission. Read more on the BIKI: selectPlayer";
	BTN_SWITCHUNIT ctrlSetTooltipColorText [1,0,0,1];
};
BTN_SWITCHUNIT ctrlAddEventHandler ["ButtonDown",{
	params ["_button"];
	if (cursorObject isKindOf "MAN" && !isPlayer cursorObject) then {
		selectPlayer cursorObject;
	} else {
		[_button] spawn {
			_button = _this select 0;
			_button ctrlSetText "SWITCH UNIT - INVALID TARGET";
			_button ctrlSetTextColor [1,0,0,1];
			uisleep 1;
			_button ctrlSetText "SWITCH UNIT";
			_button ctrlSetTextColor [1,1,1,1];
		};
	};
}];
//////////////////
} else {// UNLOAD
//////////////////

};