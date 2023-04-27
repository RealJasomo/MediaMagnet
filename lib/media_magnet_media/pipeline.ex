defmodule MediaMagnet.Pipeline do
  use Membrane.Pipeline

  @impl true
  def handle_init(path) do
    video_file = Path.join([File.cwd!(), path])

    children = [
      file_source: %Membrane.File.Source{location: video_file},
      demuxer: Membrane.MPEG.TS.Demuxer,
      audio_parser: %Membrane.AAC.Parser{out_encapsulation: :none}
    ]
  end
end
