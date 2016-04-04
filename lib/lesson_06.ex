defmodule Lesson06 do
  @behaviour :wx_object
  require Record
  Record.defrecordp :wx, Record.extract(:wx, from_lib: "wx/include/wx.hrl")
  Record.defrecordp :wxSize, Record.extract(:wxSize, from_lib: "wx/include/wx.hrl")

  defmodule State do
    defstruct [:parent, :config, :canvas, :timer, :time, :texture, :xrot, :yrot, :zrot]
  end

  defmodule Texture do
    defstruct [:id, :w, :h, :min_x, :min_y, :max_x, :max_y]
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

    state = %State{
      parent: parent,
      config: config,
      canvas: canvas,
      xrot: 0.0,
      yrot: 0.0,
      zrot: 0.0
    }

    new_state = setup_gl(state)
    timer = :timer.send_interval(20, self, :update)

    {parent, %State{ new_state | timer: timer } }
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
    new_state = :wx.batch(fn() -> render(state) end)
    {:noreply, new_state}
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

  def setup_gl(state) do
    {w, h} = :wxWindow.getClientSize(state.parent)
    resize_gl_scene(w, h)
    :gl.enable(:wx_const.gl_texture_2d)
    :gl.shadeModel(:wx_const.gl_smooth)
    :gl.clearColor(0.0, 0.0, 0.0, 0.0)
    :gl.clearDepth(1.0)
    :gl.enable(:wx_const.gl_depth_test)
    :gl.depthFunc(:wx_const.gl_lequal)
    :gl.hint(:wx_const.gl_perspective_correction_hint, :wx_const.gl_nicest)
    texture = load_texture_by_image(:wxImage.new('crate.jpg'))
    %State{ state | texture: texture }
  end

  def render(state) do
    new_state = draw(state)
    :wxGLCanvas.swapBuffers(state.canvas)
    new_state
  end

  def draw(state) do
    use Bitwise
    :gl.clear(bor(:wx_const.gl_color_buffer_bit, :wx_const.gl_depth_buffer_bit))
    :gl.loadIdentity
    :gl.translatef(0.0, 0.0, -5.0)

    :gl.rotatef(state.xrot, 1.0, 0.0, 0.0)
    :gl.rotatef(state.yrot, 0.0, 1.0, 0.0)
    :gl.rotatef(state.zrot, 0.0, 0.0, 1.0)

    :gl.bindTexture(:wx_const.gl_texture_2d, state.texture.id)
    :gl.begin(:wx_const.gl_quads)

    # Front Face
    :gl.texCoord2f(0.0, 0.0); :gl.vertex3f(-1.0, -1.0,  1.0)
    :gl.texCoord2f(1.0, 0.0); :gl.vertex3f( 1.0, -1.0,  1.0)
    :gl.texCoord2f(1.0, 1.0); :gl.vertex3f( 1.0,  1.0,  1.0)
    :gl.texCoord2f(0.0, 1.0); :gl.vertex3f(-1.0,  1.0,  1.0)

    # Back Face
    :gl.texCoord2f(1.0, 0.0); :gl.vertex3f(-1.0, -1.0, -1.0)
    :gl.texCoord2f(1.0, 1.0); :gl.vertex3f(-1.0,  1.0, -1.0)
    :gl.texCoord2f(0.0, 1.0); :gl.vertex3f( 1.0,  1.0, -1.0)
    :gl.texCoord2f(0.0, 0.0); :gl.vertex3f( 1.0, -1.0, -1.0)

    # Top Face
    :gl.texCoord2f(0.0, 1.0); :gl.vertex3f(-1.0,  1.0, -1.0)
    :gl.texCoord2f(0.0, 0.0); :gl.vertex3f(-1.0,  1.0,  1.0)
    :gl.texCoord2f(1.0, 0.0); :gl.vertex3f( 1.0,  1.0,  1.0)
    :gl.texCoord2f(1.0, 1.0); :gl.vertex3f( 1.0,  1.0, -1.0)

    # Bottom Face
    :gl.texCoord2f(1.0, 1.0); :gl.vertex3f(-1.0, -1.0, -1.0)
    :gl.texCoord2f(0.0, 1.0); :gl.vertex3f( 1.0, -1.0, -1.0)
    :gl.texCoord2f(0.0, 0.0); :gl.vertex3f( 1.0, -1.0,  1.0)
    :gl.texCoord2f(1.0, 0.0); :gl.vertex3f(-1.0, -1.0,  1.0)

    # Right Face
    :gl.texCoord2f(1.0, 0.0); :gl.vertex3f( 1.0, -1.0, -1.0)
    :gl.texCoord2f(1.0, 1.0); :gl.vertex3f( 1.0,  1.0, -1.0)
    :gl.texCoord2f(0.0, 1.0); :gl.vertex3f( 1.0,  1.0,  1.0)
    :gl.texCoord2f(0.0, 0.0); :gl.vertex3f( 1.0, -1.0,  1.0)

    # Left Face
    :gl.texCoord2f(0.0, 0.0); :gl.vertex3f(-1.0, -1.0, -1.0)
    :gl.texCoord2f(1.0, 0.0); :gl.vertex3f(-1.0, -1.0,  1.0)
    :gl.texCoord2f(1.0, 1.0); :gl.vertex3f(-1.0,  1.0,  1.0)
    :gl.texCoord2f(0.0, 1.0); :gl.vertex3f(-1.0,  1.0, -1.0)

    :gl.end

    %State{ state | xrot: state.xrot + 0.3, yrot: state.yrot + 0.2, zrot: state.zrot + 0.4 }
  end

  def load_texture_by_image(image) do
    image_width = :wxImage.getWidth(image)
    image_height = :wxImage.getHeight(image)
    width = get_power_of_two_roof(image_width)
    height = get_power_of_two_roof(image_height)
    data = get_image_data(image)

    # Create opengl texture for the image
    [texture_id] = :gl.genTextures(1)
    :gl.bindTexture(:wx_const.gl_texture_2d, texture_id)
    :gl.texParameteri(:wx_const.gl_texture_2d, :wx_const.gl_texture_mag_filter, :wx_const.gl_linear)
    :gl.texParameteri(:wx_const.gl_texture_2d, :wx_const.gl_texture_min_filter, :wx_const.gl_linear)
    format = case :wxImage.hasAlpha(image) do
      true -> :wx_const.gl_rgba
      false -> :wx_const.gl_rgb
    end
    :gl.texImage2D(:wx_const.gl_texture_2d, 0, format, width, height, 0, format, :wx_const.gl_unsigned_byte, data)
    %Texture{
      id: texture_id,
      w: image_width,
      h: image_height,
      min_x: 0,
      min_y: 0,
      max_x: image_width / width,
      max_y: image_height / height
    }
  end

  def get_image_data(image) do
    rgb = :wxImage.getData(image)
    if :wxImage.hasAlpha(image) do
      alpha = :wxImage.getAlpha(image)
      interleave_rgb_and_alpha(rgb, alpha)
    else
      rgb
    end
  end

  def interleave_rgb_and_alpha(rgb, alpha) do
    :erlang.list_to_binary(
      :lists.zipwith(fn({r, g, b}, a) ->
        <<r, g, b, a>>
      end, for <<r, g, b>> <- rgb do
        {r, g, b}
      end, for <<a>> <- alpha do
        a
      end
      )
    )
  end

  def get_power_of_two_roof(x) do
    get_power_of_two_roof_2(1, x)
  end

  def get_power_of_two_roof_2(n, x) when n >= x, do: n
  def get_power_of_two_roof_2(n, x) do
    get_power_of_two_roof_2(n*2, x)
  end
end
