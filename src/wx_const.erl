-module(wx_const).
-compile(export_all).

-include_lib("wx/include/wx.hrl").

wx_id_any() ->
    ?wxID_ANY.

wx_horizontal() ->
    ?wxHORIZONTAL.

wx_vertical() ->
    ?wxVERTICAL.

wx_expand() ->
    ?wxEXPAND.

wx_all() ->
    ?wxALL.
