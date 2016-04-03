defmodule Lesson02 do
  @behaviour :wx_object
  require Record
  Record.defrecordp :wx, Record.extract(:wx, from_lib: "wx/include/wx.hrl")
  Record.defrecordp :wxSize, Record.extract(:wxSize, from_lib: "wx/include/wx.hrl")

  defmodule State do
    defstruct [:parent, :config, :canvas, :timer, :time]
  end

  def start(config) do
    :wx_object.start_link(__MODULE__, config, [])
  end

  def init(config) do
    :wx.batch(fn() -> do_init(config) end)
  end

  def do_init(config) do
    parent = :proplists.get_value(:parent, config)
    size = :proplists.get_value(:size, config)
    opts = [size: size, style: :wx_const.wx_sunken_border]
    gl_attrib = [
      attribList: [
        :wx_const.wx_gl_rgba,
        :wx_const.wx_gl_doublebuffer,
        :wx_const.wx_gl_min_red, 8,
        :wx_const.wx_gl_min_green, 8,
        :wx_const.wx_gl_min_blue, 8,
        :wx_const.wx_gl_depth_size, 24, 0
      ]
    ]
    canvas = :wxGLCanvas.new(parent, opts ++ gl_attrib)
    :wxWindow.hide(parent)
    :wxWindow.reparent(canvas, parent)
    :wxWindow.show(parent)
    :wxGLCanvas.setCurrent(canvas)
    setup_gl(canvas)
    timer = :timer.send_interval(20, self, :update)

    {parent, %State{parent: parent, config: config, canvas: canvas, timer: timer}}
  end

  def handle_event(wx(event: wxSize(size: {w, h})), state) do
    case w == 0 or h == 0 do
      true -> :skip
      _ ->
        resize_gl_scene(w, h)
    end

    {:noreply, state}
  end

  def handle_info(:update, state) do
    :wx.batch(fn() -> render(state) end)
    {:noreply, state}
  end

  def handle_info(:stop, state) do
    :timer.cancel(state.timer)
    try do
      :wxGLCanvas.destroy(state.canvas)
    catch
      error, reason ->
        {error, reason}
    end
    {:stop, :normal, state}
  end

  def handle_call(msg, _from, state) do
    IO.puts "Call: #{inspect msg}"
    {:reply, :ok, state}
  end

  def code_change(_, _, state) do
    {:stop, :not_yet_implemented, state}
  end

  def terminate(_reason, state) do
    try do
      :wxGLCanvas.destroy(state.canvas)
    catch
      error, reason ->
        {error, reason}
    end
    :timer.cancel(state.timer)
    :timer.sleep(300)
  end

  def resize_gl_scene(width, height) do
    :gl.viewport(0, 0, width, height)
    :gl.matrixMode(:wx_const.gl_projection)
    :gl.loadIdentity
    :glu.perspective(45.0, width/height, 0.1, 100.0)
    :gl.matrixMode(:wx_const.gl_modelview)
    :gl.loadIdentity
  end

  def setup_gl(win) do
    {w, h} = :wxWindow.getClientSize(win)
    resize_gl_scene(w, h)
    :gl.shadeModel(:wx_const.gl_smooth)
    :gl.clearColor(0.0, 0.0, 0.0, 0.0)
    :gl.clearDepth(1.0)
    :gl.enable(:wx_const.gl_depth_test)
    :gl.depthFunc(:wx_const.gl_lequal)
    :gl.hint(:wx_const.gl_perspective_correction_hint, :wx_const.gl_nicest)
    :ok
  end

  def render(state) do
    draw()
    :wxGLCanvas.swapBuffers(state.canvas)
  end

  def draw do
    use Bitwise
    :gl.clear(bor(:wx_const.gl_color_buffer_bit, :wx_const.gl_depth_buffer_bit))
    :gl.loadIdentity
    :gl.translatef(-1.5, 0.0, -6.0)
    :gl.begin(:wx_const.gl_triangles)
    :gl.vertex3f(0.0, 1.0, 0.0)
    :gl.vertex3f(-1.0, -1.0, 0.0)
    :gl.vertex3f(1.0, -1.0, 0.0)
    :gl.end

    :gl.translatef(3.0, 0.0, 0.0)
    :gl.begin(:wx_const.gl_quads)
    :gl.vertex3f(-1.0,  0.0, 0.0)
    :gl.vertex3f( 1.0,  1.0, 0.0)
    :gl.vertex3f( 1.0, -1.0, 0.0)
    :gl.vertex3f(-1.0, -1.0, 0.0)
    :gl.end
    :ok
  end
end
