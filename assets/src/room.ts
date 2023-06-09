import { MEDIA_CONSTRAINTS, LOCAL_PEER_ID } from './consts';
import {
	addVideoElement,
	getRoomId,
	removeVideoElement,
	setErrorMessage,
	setParticipantsList,
	attachStream,
	setupDisconnectButton,
} from './room_ui';
import {
	MembraneWebRTC,
	Peer,
	SerializedMediaEvent,
} from '@membraneframework/membrane-webrtc-js';
import { Push, Socket } from 'phoenix';
import { parse } from 'query-string';

export class Room {
	private peers: Peer[] = [];
	private displayName: string;
	private localStream: MediaStream | undefined;
	private webrtc: MembraneWebRTC;

	private socket;
	private webrtcSocketRefs: string[] = [];
	private webrtcChannel;

	constructor() {
		this.socket = new Socket('/socket');
		this.socket.connect();
		this.displayName = this.parseUrl();
		this.webrtcChannel = this.socket.channel(`room:${getRoomId()}`);

		this.webrtcChannel.onError(() => {
			this.socketOff();
			window.location.reload();
		});
		this.webrtcChannel.onClose(() => {
			this.socketOff();
			window.location.reload();
		});

		this.webrtcSocketRefs.push(this.socket.onError(this.leave));
		this.webrtcSocketRefs.push(this.socket.onClose(this.leave));

		this.webrtc = new MembraneWebRTC({
			callbacks: {
				onSendMediaEvent: (mediaEvent: SerializedMediaEvent) => {
					this.webrtcChannel.push('mediaEvent', { data: mediaEvent });
				},
				onConnectionError: setErrorMessage,
				onJoinSuccess: (peerId, peersInRoom) => {
					this.localStream!.getTracks().forEach((track) =>
						this.webrtc.addTrack(track, this.localStream!, {})
					);

					this.peers = peersInRoom;
					this.peers.forEach((peer) => {
						addVideoElement(peer.id, peer.metadata.displayName, false);
					});
					this.updateParticipantsList();
				},
				onJoinError: (metadata) => {
					throw `Peer denied.`;
				},
				onTrackReady: ({ stream, peer, metadata }) => {
					attachStream(stream!, peer.id);
				},
				onTrackAdded: (ctx) => {},
				onTrackRemoved: (ctx) => {},
				onPeerJoined: (peer) => {
					this.peers.push(peer);
					this.updateParticipantsList();
					addVideoElement(peer.id, peer.metadata.displayName, false);
				},
				onPeerLeft: (peer) => {
					this.peers = this.peers.filter((p) => p.id !== peer.id);
					removeVideoElement(peer.id);
					this.updateParticipantsList();
				},
				onPeerUpdated: (ctx) => {},
			},
		});

		this.webrtcChannel.on('mediaEvent', (event: any) =>
			this.webrtc.receiveMediaEvent(event.data)
		);
	}

	public join = async () => {
		try {
			await this.init();
			setupDisconnectButton(() => {
				this.leave();
				window.location.replace('');
			});
			this.webrtc.join({ displayName: this.displayName });
		} catch (error) {
			console.error('Error while joining to the room:', error);
		}
	};

	private init = async () => {
		try {
			this.localStream = await navigator.mediaDevices.getUserMedia(
				MEDIA_CONSTRAINTS
			);
		} catch (error) {
			console.error(error);
			setErrorMessage(
				'Failed to setup video room, make sure to grant camera and microphone permissions'
			);
			throw 'error';
		}

		addVideoElement(LOCAL_PEER_ID, 'Me', true);
		attachStream(this.localStream!, LOCAL_PEER_ID);
		
		const videoChannel = this.socket.channel(`together:${getRoomId()}`);
		videoChannel.join();

		document.querySelectorAll('#files>tr').forEach(tr => tr.addEventListener('click', event => {
			const new_video = tr.id;
			videoChannel.push("switch", {new_video});
			
		}));


		let video_ele = document.getElementById("video-element");
			if(video_ele) {
				video_ele.addEventListener("play", () => {
					videoChannel.push("play", {})
				})
				video_ele.addEventListener("pause", () => {
					videoChannel.push("pause", {})	
				});

				videoChannel.on("play", () => {
					const ele = document.getElementById("video-element")
					if (ele) {
						(ele as HTMLVideoElement).play()
					}
				});
				videoChannel.on("pause", () => {
					const ele = document.getElementById("video-element")
					if (ele) {
						(ele as HTMLVideoElement).pause()
					}
				});
		}

		let src_elem = document.querySelector("#video-element>source");
		if(src_elem) {
			videoChannel.on("switch", ({new_video}) => {
				(src_elem as HTMLSourceElement).src = `/stream/${new_video}`;
				video_ele!.load();
			});
		}
		await this.phoenixChannelPushResult(this.webrtcChannel.join());
	};

	private leave = () => {
		this.webrtc.leave();
		this.webrtcChannel.leave();
		this.socketOff();
	};

	private socketOff = () => {
		this.socket.off(this.webrtcSocketRefs);
		while (this.webrtcSocketRefs.length > 0) {
			this.webrtcSocketRefs.pop();
		}
	};

	private parseUrl = (): string => {
		const { display_name: displayName } = parse(document.location.search);

		// remove query params without reloading the page
		window.history.replaceState(null, '', window.location.pathname);

		return displayName as string;
	};

	private updateParticipantsList = (): void => {
		const participantsNames = this.peers.map((p) => p.metadata.displayName);

		if (this.displayName) {
			participantsNames.push(this.displayName);
		}

		setParticipantsList(participantsNames);
	};

	private phoenixChannelPushResult = async (push: Push): Promise<any> => {
		return new Promise((resolve, reject) => {
			push
				.receive('ok', (response: any) => resolve(response))
				.receive('error', (response: any) => reject(response));
		});
	};
}
