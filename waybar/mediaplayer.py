#!/usr/bin/env python3

import argparse
import logging
import sys
import signal
import gi
import json

gi.require_version('Playerctl', '2.0')
from gi.repository import Playerctl, GLib

logger = logging.getLogger(__name__)


def write_output(text, player):
    logger.info('Writing output')

    output = {
        'text': text,
        'class': 'custom-' + player.props.player_name,
        'alt': player.props.player_name
    }

    sys.stdout.write(json.dumps(output) + '\n')
    sys.stdout.flush()


def on_play(player, status, manager):
    logger.info('Received playback status change')
    on_metadata(player, player.props.metadata, manager)


def on_metadata(player, metadata, manager):
    logger.info('Received metadata update')
    track_info = ''

    artist = player.get_artist()
    title = player.get_title()

    if artist and title:
        track_info = f'{artist} - {title}'
    else:
        track_info = title or 'No Track Info'

    if player.props.status != 'Playing':
        track_info = ' ' + track_info

    write_output(track_info, player)


def on_player_appeared(manager, player, selected_player=None):
    if player is not None and (selected_player is None or player.name == selected_player):
        init_player(manager, player)
    else:
        logger.debug("New player appeared, not selected one, skipping")


def on_player_vanished(manager, player):
    logger.info('Player vanished')
    sys.stdout.write('\n')
    sys.stdout.flush()


def init_player(manager, name):
    logger.debug(f'Initializing player: {name.name}')
    player = Playerctl.Player.new_from_name(name)
    player.connect('playback-status', on_play, manager)
    player.connect('metadata', on_metadata, manager)
    manager.manage_player(player)
    on_metadata(player, player.props.metadata, manager)


def signal_handler(sig, frame):
    logger.debug('Received exit signal, quitting')
    sys.stdout.write('\n')
    sys.stdout.flush()
    sys.exit(0)


def parse_arguments():
    parser = argparse.ArgumentParser()
    parser.add_argument('-v', '--verbose', action='count', default=0)
    parser.add_argument('--player')  # optional: restrict to a specific player
    return parser.parse_args()


def main():
    args = parse_arguments()

    logging.basicConfig(stream=sys.stderr, level=logging.DEBUG,
                        format='%(name)s %(levelname)s %(message)s')

    logger.setLevel(max((3 - args.verbose) * 10, 0))
    logger.debug(f'Arguments: {vars(args)}')

    manager = Playerctl.PlayerManager()
    loop = GLib.MainLoop()

    manager.connect('name-appeared', lambda *a: on_player_appeared(*a, args.player))
    manager.connect('player-vanished', on_player_vanished)

    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

    for player in manager.props.player_names:
        if args.player and player.name != args.player:
            logger.debug(f'Skipping player {player.name}')
            continue
        init_player(manager, player)

    loop.run()


if __name__ == '__main__':
    main()


