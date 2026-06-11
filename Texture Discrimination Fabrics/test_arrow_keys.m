k = waitforbuttonpress;
% 28 leftarrow
% 29 rightarrow
% 30 uparrow
% 31 downarrow
value = double(get(gcf,'CurrentCharacter'));

% In App Designer and in apps created using the uifigure function, 
% use uiwait to block statements from executing. 
% To resume program execution when the app user clicks a mouse button
% or presses a key, specify a WindowButtonDownFcn or WindowKeyPressFcn
% callback that calls uiresume.
% 
% For example, this code creates a UI figure that resumes program 
% execution when a user clicks in the figure window.
% 
% fig = uifigure('WindowButtonDownFcn',@(src,event)uiresume(src));
% Call uiwait to block program execution until uiresume is called
% or the figure is deleted. Create a UIAxes object and parent it
% to the figure. The set of axes does not appear.
% 
% uiwait(fig);
% ax = uiaxes(fig);