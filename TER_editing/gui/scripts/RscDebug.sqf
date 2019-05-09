#include "ctrls.inc"
#include "\a3\ui_f\hpp\definedikcodes.inc"

disableSerialization;
params ["_control"];
waitUntil {!isNull (findDisplay 49)};
if !([] call BIS_fnc_isDebugConsoleAllowed) exitWith {
	_control ctrlShow false;
	_control ctrlEnable false;
};// debug console disabled
if (getResolution select 5 > 0.7) exitWith {
	if !(uiNamespace getVariable ["TER_3den_uiSize2BigShown",false]) then {
		["The debug console is not made for UI sizes greater than Normal (Large, Very Large). The remaining space is just not enough.","@7erra's Editing Extension",false,true] spawn BIS_fnc_GUImessage;
		uiNamespace setVariable ["TER_3den_uiSize2BigShown",true];
	};
	_control ctrlShow false;
	_control ctrlEnable false;
};
uiNamespace setVariable ["TER_3den_uiSize2BigShown",false];
_escapeMenu = findDisplay 49;


// pages listbox:
{XLB_PAGES lbAdd _x} forEach [
	"General",
	"More Watch Fields",
	"Custom Commands",
	"BIKI Links / Target Debug / Saved Watch Entries",
	"Unit Live Watch"
];
XLB_PAGES setVariable ["TER_3den_xlbPagesInit",true];
XLB_PAGES ctrlAddEventHandler ["LBSelChanged",{
	params ["_ctrl","_index"];
	_isInit = XLB_PAGES getVariable ["TER_3den_xlbPagesInit",false];
	if (_isInit) then {_ctrl setVariable ["TER_3den_xlbPagesInit",false];};
	_pageCount = 5;
	_allPages = [];
	_allPages resize _pageCount;
	_curCount = 0;
	_allPages = _allPages apply {_curCount = _curCount +1; ESC_CTRL(73040 +_curCount)};
	_loadPageCtrl = ESC_CTRL(73041 +_index);
	{
		_pagescript = format ["TER_Editing\gui\scripts\RscDebug\page%1.sqf",_foreachIndex+1];
		_curCtrlPos = ctrlPosition _x;
		if (_x == _loadPageCtrl) then { // appear
			// load script
			[1] execVM _pagescript;
			_curCtrlPos set [0, 0.5 * GUI_GRID_W];
			_x ctrlSetPosition _curCtrlPos;
			_x ctrlCommit 0;
			_curCtrlPos set [0, 0.5 * GUI_GRID_W];
			_curCtrlPos set [2, 21 * GUI_GRID_W];
		} else { // disappear
			[0] execVM _pagescript;
			_curCtrlPos set [0, 21.5 * GUI_GRID_W];
			_curCtrlPos set [2, 0 * GUI_GRID_W];
		};
		_x ctrlSetPosition _curCtrlPos;
		_commit = [0.2,0] select _isInit;
		_x ctrlCommit _commit;
	} forEach _allPages;
	uiNamespace setVariable ["TER_3den_debugIndex",_index];
}];
_lastIndex = uiNamespace getVariable ["TER_3den_debugIndex",0];
XLB_PAGES lbSetCurSel _lastIndex;

// escape menu EHs for restart and exit
{ESC_CTRL(_x) ctrlShow false;} forEach [1000,1001];
ESC_DISPLAY displayRemoveAllEventHandlers "MouseButtonDown";
ESC_DISPLAY displayAddEventHandler ["KeyDown",{
	params ["_display","_key","_shift","_ctrl","_alt"];
	if (_key == DIK_R && _ctrl && !_shift) then { // restart
		_restartBtn = _display displayCtrl 119;
		ctrlActivate _restartBtn;
	};
	if (_key == DIK_E && _ctrl) then { // exit
		_exitBtn = _display displayCtrl 104;
		ctrlActivate _exitBtn;
	};
}];

// save commands
#define CUR_CC_CONTROLS (allControls ESC_DISPLAY select {ctrlParentControlsGroup _x == GRP_CC_COMMANDS})
_escapeMenu displayAddEventHandler ["unLoad",{
	params ["_display"];
	if (DEBUG_PAGE_2 getVariable ["pageInitialized",false]) then {
		_inputControls = (allControls ESC_DISPLAY) select {ctrlParentControlsGroup _x == GRP_WATCHFIELDS};
		_inputControlsText = _inputControls apply {ctrlText (_x controlsGroupCtrl 7490)};
		profileNamespace setVariable ["TER_3den_watchCommands",_inputControlsText];
		saveProfileNamespace;
	};

	if (DEBUG_PAGE_3 getVariable ["pageInitialized",false]) then {
		_allCCEdits = CUR_CC_CONTROLS apply {_x controlsGroupCtrl 7494};
		_allCCEditsText = _allCCEdits apply {ctrlText _x};
		_allCCEditsText = _allCCEditsText select {_x != ""};
		profileNamespace setVariable ["TER_3den_ccArray",_allCCEditsText];
		saveProfileNamespace;
	};
}];

// btn clear chat:
BTN_CLEARCHAT ctrlAddEventHandler ["ButtonClick",{
	clearRadio;
}];

