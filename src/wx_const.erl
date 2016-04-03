-module(wx_const).
-compile(export_all).

-include_lib("wx/include/wx.hrl").
-include_lib("wx/include/gl.hrl").
-include_lib("wx/include/glu.hrl").

wx_id_any() ->
    ?wxID_ANY.

wx_sunken_border() ->
    ?wxSUNKEN_BORDER.

wx_gl_rgba() ->
    ?WX_GL_RGBA.

wx_gl_doublebuffer() ->
    ?WX_GL_DOUBLEBUFFER.

wx_gl_min_red() ->
    ?WX_GL_MIN_RED.

wx_gl_min_green() ->
    ?WX_GL_MIN_GREEN.

wx_gl_min_blue() ->
    ?WX_GL_MIN_BLUE.

wx_gl_depth_size() ->
    ?WX_GL_DEPTH_SIZE.

wx_horizontal() ->
    ?wxHORIZONTAL.

wx_vertical() ->
    ?wxVERTICAL.

wx_expand() ->
    ?wxEXPAND.

wx_all() ->
    ?wxALL.

gl_projection() ->
    ?GL_PROJECTION.

gl_modelview() ->
    ?GL_MODELVIEW.

gl_smooth() ->
    ?GL_SMOOTH.

gl_depth_test() ->
    ?GL_DEPTH_TEST.

gl_lequal() ->
    ?GL_LEQUAL.

gl_perspective_correction_hint() ->
    ?GL_PERSPECTIVE_CORRECTION_HINT.

gl_nicest() ->
    ?GL_NICEST.

gl_color_buffer_bit() ->
    ?GL_COLOR_BUFFER_BIT.

gl_depth_buffer_bit() ->
    ?GL_DEPTH_BUFFER_BIT.
