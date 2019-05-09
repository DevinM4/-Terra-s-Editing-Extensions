#include "..\ctrls.inc"
#include "\A3\ui_f\hpp\defineDIKCodes.inc"
params ["_mode"];
/////////////////////////////
if (_mode == 1) then {// LOAD
/////////////////////////////
if (DEBUG_PAGE_4 getVariable ["pageInitialized",false]) exitWith {};
DEBUG_PAGE_4 setVariable ["pageInitialized",true];


////////////////////////////////////// Watch History //////////////////////////////////////
#define WATCH_HISTORY_ARRAY (profileNamespace getVariable ["TER_3den_watchHistory_array",[]])
// load previous

{
	_x ctrlAddEventHandler ["KeyDown",{
		params ["_control","_key","_shift","_ctrl","_alt"];
		_textEdit = ctrlText _control;
		_historyArray = WATCH_HISTORY_ARRAY;
		if (_ctrl && _key == DIK_F && (!isNil compile _textEdit) && !(toLower _textEdit in (_historyArray apply {toLower _x}))) then {// favourite
			reverse _historyArray;
			_historyArray pushBackUnique _textEdit;
			reverse _historyArray;
			profileNamespace setVariable ["TER_3den_watchHistory_array",_historyArray];
			saveProfileNamespace;
			lbClear LB_WATCHHISTORY;
			{LB_WATCHHISTORY lbAdd _x} forEach _historyArray;
		};
	}];
} forEach WATCH_IN_ARRAY;

// listbox with commands
{LB_WATCHHISTORY lbAdd _x} forEach WATCH_HISTORY_ARRAY;
LB_WATCHHISTORY ctrlAddEventHandler ["LBDblClick",{
	params ["_listbox","_index"];
	_command = _listbox lbText _index;
	_edInput = switch (lbCurSel COMBO_WATCHIN) do {
		case 1: {
			_emptyTextArray = WATCH_IN_ARRAY select {ctrlText _x == ""};
			reverse _emptyTextArray;
			if (count _emptyTextArray == 0) then {WATCH_IN_4} else {_emptyTextArray select 0};
		};
		case 2: {WATCH_IN_1};
		case 3: {WATCH_IN_2};
		case 4: {WATCH_IN_3};
		case 5: {WATCH_IN_4};
		default {
			_emptyTextArray = WATCH_IN_ARRAY select {ctrlText _x == ""};
			if (count _emptyTextArray == 0) then {WATCH_IN_1} else {_emptyTextArray select 0};
		};
	};
	_edInput ctrlSetText _command;
}];
// combo: which input
{
	_index = COMBO_WATCHIN lbAdd toUpper format ["Input: %1",_x];
	COMBO_WATCHIN lbSetTooltip [_index,"Select which Input should be chosen"];
} forEach ["First empty","Last empty",1,2,3,4];
COMBO_WATCHIN lbSetCurSel 0;

LB_WATCHHISTORY ctrlAddEventHandler ["KeyDown",{
	params ["_listbox","_key"];
	if (_key == DIK_DELETE) then {
		_command = _listbox lbText (lbCurSel _listbox);
		_historyArray = WATCH_HISTORY_ARRAY;
		_historyArray = _historyArray -[_command];
		profileNamespace setVariable ["TER_3den_watchHistory_array",_historyArray];
		_listbox lbDelete (lbCurSel _listbox);
	};

}];
// clear history:
BTN_CLEARHISTORY ctrlAddEventHandler ["ButtonClick",{
	params ["_button"];
		profileNamespace setVariable ["TER_3den_watchHistory_array",nil];
		lbClear LB_WATCHHISTORY;
}];


////////////////////////////////////// Target Debug //////////////////////////////////////
#define DEBUG_TARGET_COMMANDS (uiNamespace getVariable ["TER_3den_targetDebugCommands",[]])
#define DEBUG_TARGET_COMMANDS_SET(VAR) uiNamespace setVariable ["TER_3den_targetDebugCommands",VAR];
_cbTargetDebug = CB_TARGETDEBUG;
if (!isNull (uiNamespace getVariable ["TER_3den_RscTargetDebug_display",displayNull])) then {
	_cbTargetDebug cbSetChecked true;
};
_cbTargetDebug ctrlAddEventHandler ["CheckedChanged",{
	params ["_ctrl","_state"];
	if (_state == 1) then {// activate target debugging
		("TER_3den_RscTargetDebug_layer" call BIS_fnc_rscLayer) cutRsc ["TER_RscDisplayTargetDebug","PLAIN"];
		// spawn start
		[] spawn {
			_display = uiNamespace getVariable ["TER_3den_RscTargetDebug_display",displayNull];
			_fncNewLine = {
				params ["_lText","_rText"];
				_text = _text +format ["<t underline='true'>%1</t><br/>   %2<br/>",_lText,_rText,toString [10]];
			};
			// loop start
			_radius = 20;
			while {!isNull _display} do {
				_entities = (getPos player nearEntities _radius)-[player];
				{
					_object = _x;
					_text = "";
					{
						_command = _x;
						_result = call compile _command;
						[_command,str _result] call _fncNewLine;
					} forEach DEBUG_TARGET_COMMANDS;

					// create new control for each entity
					private "_stxtInfo";
					if (isNull (_x getVariable ["TER_3den_stxtInfoControl",controlNull])) then{
						_stxtInfo = _display ctrlCreate ["RscStructuredText",-1];
						_stxtInfo ctrlSetBackgroundColor [0,0,0,0.2];
						_x setVariable ["TER_3den_stxtInfoControl",_stxtInfo];
					} else {
						_stxtInfo = _x getVariable ["TER_3den_stxtInfoControl",controlNull];
					};
					// set control pos
					_stxtInfo ctrlSetStructuredText parseText _text;
					if (count worldToScreen getPos _x > 0) then {
						_relPos = worldToScreen getPos _x;
						{_relPos set _x} forEach [[2,ctrlTextWidth _stxtInfo],[3,ctrlTextHeight _stxtInfo]];
						_stxtInfo ctrlSetPosition _relPos;
					};
					_stxtInfo ctrlCommit 0;

				} forEach _entities;
				{
					// hide controls which are beyond 100 m
					_stxtInfo = _x getVariable ["TER_3den_stxtInfoControl",controlNull];
					_stxtInfo ctrlSetPosition [0,0,0,0];
					_stxtInfo ctrlCommit 0;
				} forEach ((getPos player nearEntities (_radius +10))-_entities +allDead);
				_curFrame = diag_frameno;
				waitUntil {_curFrame != diag_frameno};
			};
			// loop end
		};
		// spawn end
	} else {// close display, end target debugging
		"TER_3den_RscTargetDebug_layer" cutFadeOut 0;
	};
}];

// target debugging, add command
_btnTargetDebugAdd = BTN_TARGETDEBUG_ADD;
_btnTargetDebugAdd ctrlAddEventHandler ["ButtonClick",{
	params ["_button"];
	_escapeMenu = findDisplay 49;
	_edCommand = _escapeMenu displayCtrl 7406;
	_command = ctrlText _edCommand;
	//-- TODO: add check, if nil exit
	if !(["_object", _command] call BIS_fnc_inString) then {_command = _command +" _object"};
	//if (isNil compile _command) exitWith {_edCommand ctrlSettext "#ERROR - INVALID COMMAND"};
	// update global array
	_targetCommands = DEBUG_TARGET_COMMANDS;
	_prevCount = count _targetCommands;
	_targetCommands pushBackUnique _command;
	if (_prevCount == count _targetCommands) exitWith {};
	_lb_targetDebug_commands = LB_TARGETDEBUG_COMMANDS;
	_lb_targetDebug_commands lbAdd _command;
	DEBUG_TARGET_COMMANDS_SET(_targetCommands)

	_edCommand ctrlSetText "";
	ctrlSetFocus _edCommand;
}];
// target debugging, listbox
_lb_targetDebug_commands = LB_TARGETDEBUG_COMMANDS;
if (count DEBUG_TARGET_COMMANDS == 0) then {
	_startCommands = ["_object","typeOf _object"];
	{
		_lb_targetDebug_commands lbAdd _x;
	} forEach _startCommands;
	DEBUG_TARGET_COMMANDS_SET(_startCommands)
} else {
	{
		_lb_targetDebug_commands lbAdd _x;
	} forEach DEBUG_TARGET_COMMANDS;
};
_lb_targetDebug_commands ctrlAddEventHandler ["LBDblClick",{
	params ["_listbox","_index"];
	_command = _listbox lbText _index;
	_newCommandArray = DEBUG_TARGET_COMMANDS -[_command];
	DEBUG_TARGET_COMMANDS_SET(_newCommandArray)
	_listbox lbDelete _index;
}];

/////////////////////////////////////// BIKI Links ///////////////////////////////////////
_prevLinkText = uiNamespace getVariable ["TER_3den_links",""];
STXT_LINKS ctrlSetStructuredText parseText _prevLinkText;
STXT_LINKS ctrlSetPosition [0,0,21 * GUI_GRID_W,(ctrlTextHeight STXT_LINKS) max (6 * GUI_GRID_H)];
STXT_LINKS ctrlCommit 0;

BTN_LINKADD ctrlAddEventHandler ["ButtonClick",{
	params ["_button"];
	_command = ctrlText ED_LINK;
	if (_command == "#CLEAR") exitWith {
		uiNamespace setVariable ["TER_3den_links",""];
		STXT_LINKS ctrlSetStructuredText parseText "";
	};
	_linkText = if (_command find "http" == -1) then {
		format ["<a href='https://community.bistudio.com/wiki/%1'>%1</a><br/>",_command];
	} else {
		format ["<a href='%1'>%1</a><br/>",_command];
	};
	_prevLinkText = uiNamespace getVariable ["TER_3den_links",""];
	if (_prevLinkText find _linkText != -1) then {
		_prevLinkText = (_prevLinkText select [0,_prevLinkText find _linkText]) + (_prevLinkText select [(_prevLinkText find _linkText) +count _linkText, count _prevLinkText]);
	};
	_newLinkText = if (count _prevLinkText == count (uiNamespace getVariable ["TER_3den_links",""])) then {
		 _linkText +_prevLinkText;
	} else {
		_prevLinkText;
	};
	uiNamespace setVariable ["TER_3den_links",_newLinkText];
	STXT_LINKS ctrlSetStructuredText parseText _newLinkText;
	STXT_LINKS ctrlSetPosition [0,0,21 * GUI_GRID_W,(ctrlTextHeight STXT_LINKS) max (6 * GUI_GRID_H)];
	STXT_LINKS ctrlCommit 0;
}];

_tooltipArray = [
	"You can",
	"a) Add a command (case sensitive)",
	"b) Add a link",
	"c) Use ""#CLEAR"" to wipe the history",
	"d) Remove a link by adding the same link again"
];
ED_LINK ctrlSetTooltip (_tooltipArray joinString toString [10]);

/////////////////
} else {// UNLOAD
/////////////////

};