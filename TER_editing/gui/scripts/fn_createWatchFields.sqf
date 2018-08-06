#include "ctrls.inc"
disableSerialization;

_newWatchGroup = ESC_DISPLAY ctrlCreate ["TER_3den_RscWatchGroupControl",-1,GRP_WATCHFIELDS];
_curPos = ctrlPosition _newWatchGroup;
_yPos = ((count WATCH_GROUP_CONTROLS)-1) * 2.3 * GUI_GRID_H;
_curPos set [1,_yPos];
_newWatchGroup ctrlSetPosition _curPos;
_newWatchGroup ctrlCommit 0;
_edInput = _newWatchGroup controlsGroupCtrl 7490;
_btnDelete = _newWatchGroup controlsGroupCtrl 7491;
_edOutput = _newWatchGroup controlsGroupCtrl 7492;

_edInput setVariable ["TER_3den_isFocused",false];
_edInput ctrlAddEventHandler ["SetFocus",{(_this select 0) setVariable ["TER_3den_isFocused",true];}];
_edInput ctrlAddEventHandler ["KillFocus",{(_this select 0) setVariable ["TER_3den_isFocused",false];}];
[_edInput,_edOutput] spawn {
	params ["_edInput","_edOutput"];
	while {!isNull _edInput} do {
		_command = ctrlText _edInput;
		_result = if (isNil compile _command) then {""} else {
			str ([] call compile _command);
		};
		_edOutput ctrlSetText _result;
		_frame = diag_frameno;
		if (_edInput getVariable ["TER_3den_isFocused",false]) then {
			waitUntil {_frame < diag_frameno};
		} else {
			waitUntil {_frame +10 < diag_frameno};
		};
	};
};
_btnDelete ctrlAddEventHandler ["ButtonClick",{
	params ["_button"];

	_thisGroup = ctrlParentControlsGroup _button;
	_groupsLeft = (WATCH_GROUP_CONTROLS -[_thisGroup]);
	{
		_curPos = ctrlPosition _x;
		_yPos = _forEachIndex * 2.3 * GUI_GRID_H;
		_curPos set [1,_yPos];
		_x ctrlSetPosition _curPos;
		_x ctrlCommit 0;
	} forEach _groupsLeft;

	ctrlDelete _thisGroup;
}];
[_edInput,_edOutput,_btnDelete];