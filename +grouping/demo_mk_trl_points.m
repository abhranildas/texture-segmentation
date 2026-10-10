function demo_mk_trl_points()
% DEMO_MK_TRL_POINTS  Demonstrate one call to GROUPING.MK_TRL_POINTS.
%   grouping.demo_mk_trl_points()
%
%   Builds a session with GROUPING.MK_TEXSEG_SESSION, picks the trial at a
%   fixed position in the randomized presentation order, and displays that
%   trial's cue, texture and feedback images.
%
%   Broken as written, on two independent counts - see bug B2.5 in
%   docs/repo-cleanup.md: GROUPING.MK_TEXSEG_SESSION is called with no
%   arguments below, but its signature requires tex_set and n_tex; and even
%   past that, session.texset (used here) is never a field of the session
%   struct GROUPING.MK_TEXSEG_SESSION returns - that struct's field is
%   session.tex_set. Both are left exactly as written; the mismatched field
%   name in particular is a frozen cross-file name, not a rename target.
%
%   Inputs
%     none.
%
%   Output
%     none (displays three figures).
%
%   See also GROUPING.MK_TEXSEG_SESSION, GROUPING.MK_TRL_POINTS.

    session = grouping.mk_texseg_session();
    order_index = 10;
    trial = session.tperm(order_index);
    contrast = session.cntrst(order_index);
    [condition, cue_img, tex_img, feedback_img] = ...
        grouping.mk_trl_points(trial, session.sz, session.pw, session.m0, ...
        session.texset, contrast, session.cuelocs, session.texs, session.maps);

    figure;
    imshow(cast(cue_img, "uint8"));
    figure;
    imshow(cast(tex_img, "uint8"));
    figure;
    imshow(cast(feedback_img, "uint8"));
end
