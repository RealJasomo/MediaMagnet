defmodule MediaMagnet.Pipeline do
  use Membrane.Pipeline

  @impl true
  def handle_init(path) do
    video_file = Path.join([File.cwd!(), path])

    children = [
      file_source: %Membrane.File.Source{location: video_file},
      demuxer: Membrane.MPEG.TS.Demuxer,
      audio_parser: %Membrane.AAC.Parser{out_encapsulation: :none},
      video_parser: %Membrane.H264.FFmpeg.Parser{
        framerate: {25, 1},
        attach_nalus?: true
      },
      audio_payloader: Membrane.MP4.Payloader.AAC,
      video_payloader: Membrane.MP4.Payloader.H264,
      cmaf: %Membrane.MP4.Muxer.CMAF{segment_duration: Membrane.Time.seconds(2)},
      sink: %Membrane.HTTPAdaptiveStream.Sink{
        manifest_module: Membrane.HTTPAdaptiveStream.HLS,
        target_window_duration: 30 |> Membrane.Time.seconds(),
        target_segment_duration: 2 |> Membrane.Time.seconds(),
        persist?: false,
        storage: %Membrane.HTTPAdaptiveStream.Storages.FileStorage{
          directory: "output"
        }
      }
    ]

    links = [
      link(:file_source) |> to(:demuxer),
      link(:demuxer)
      |> via_out(Pad.ref(:output, 0x100))
      |> to(:video_parser)
      |> to(:video_payloader)
      |> to(:cmaf),
      link(:demuxer)
      |> via_out(Pad.ref(:output, 0x101))
      |> to(:audio_parser)
      |> to(:audio_payloader)
      |> to(:cmaf),
      link(:cmaf) |> to(:sink)
    ]

    spec = %ParentSpec{
      children: children,
      links: links
    }

    {{:ok, spec: spec}, %{}}
  end

  @impl true
  def handle_notification({:mpeg_ts_stream_info, _info}, :demuxer, _ctx, state) do
    {{:ok, forward: {:demuxer, :pads_ready}}, state}
  end

  @impl true
  def handle_notification(_notification, _element, _ctx, state), do: {:ok, state}

  # Detect that processing has finished and terminate the pipeline
  @impl true
  def handle_element_end_of_stream({:sink, _pad}, _ctx, state) do
    __MODULE__.terminate(self())
    {:ok, state}
  end
end
