defmodule MediaMagnet.Pipeline do
  use Membrane.Pipeline

  @impl true
  def handle_init(path) do
    video_file = Path.join([File.cwd!(), path])

    children = [
      file_source: %Membrane.File.Source{location: video_file},
      demuxer: Membrane.MP4.Demuxer,
      video_parser: %Membrane.H264.FFmpeg.Parser{framerate: {24, 1}},
      video_decoder: Membrane.H264.FFmpeg.Decoder,
      audio_decoder: Membrane.AAC.FDK.Decoder,
      hls: %Membrane.HTTPAdaptiveStream.SinkBin{
        manifest_module: Membrane.HTTPAdaptiveStream.HLS,
        persist?: false,
        storage: %Membrane.HTTPAdaptiveStream.Storages.FileStorage{directory: "output"}
      }
    ]

    links = [
      link(:file_source)
      |> to(:demuxer),
      link(:demuxer)
      |> to(:video_parser),
      link(:video_parser)
      |> to(:video_decoder),
      link(:demuxer)
      |> to(:audio_decoder),
      link(:audio_decoder)
      |> to(:hls),
      link(:hls)
    ]

    spec = %ParentSpec{
      children: children,
      links: links
    }

    {{:ok, spec: spec}, %{}}
  end
end
