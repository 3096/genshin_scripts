# don't forget to run the script as admin

import asyncio

import mido
import pynput.keyboard
from typing import List

MIDI_FILE_PATH = r"path to your midi file here"
ROOT_NOTE = 48
START_KEY_COMBO = [pynput.keyboard.Key.alt_l, pynput.keyboard.KeyCode.from_char('3')]
STOP_KEY_COMBO = [pynput.keyboard.Key.space]


class NoteKeyMap:
    KEY_STEPS = [
        (0, pynput.keyboard.KeyCode.from_vk(0x5A)),  # z
        (2, pynput.keyboard.KeyCode.from_vk(0x58)),  # x
        (4, pynput.keyboard.KeyCode.from_vk(0x43)),  # c
        (5, pynput.keyboard.KeyCode.from_vk(0x56)),  # v
        (7, pynput.keyboard.KeyCode.from_vk(0x42)),  # b
        (9, pynput.keyboard.KeyCode.from_vk(0x4E)),  # n
        (11, pynput.keyboard.KeyCode.from_vk(0x4D)),  # m
        (12, pynput.keyboard.KeyCode.from_vk(0x41)),  # a
        (14, pynput.keyboard.KeyCode.from_vk(0x53)),  # s
        (16, pynput.keyboard.KeyCode.from_vk(0x44)),  # d
        (17, pynput.keyboard.KeyCode.from_vk(0x46)),  # f
        (19, pynput.keyboard.KeyCode.from_vk(0x47)),  # g
        (21, pynput.keyboard.KeyCode.from_vk(0x48)),  # h
        (23, pynput.keyboard.KeyCode.from_vk(0x4A)),  # j
        (24, pynput.keyboard.KeyCode.from_vk(0x51)),  # q
        (26, pynput.keyboard.KeyCode.from_vk(0x57)),  # w
        (28, pynput.keyboard.KeyCode.from_vk(0x45)),  # e
        (29, pynput.keyboard.KeyCode.from_vk(0x52)),  # r
        (31, pynput.keyboard.KeyCode.from_vk(0x54)),  # t
        (33, pynput.keyboard.KeyCode.from_vk(0x59)),  # y
        (35, pynput.keyboard.KeyCode.from_vk(0x55)),  # u
    ]

    def __init__(self, root_note):
        self.map = {}
        for key_step in self.KEY_STEPS:
            self.map[root_note + key_step[0]] = key_step[1]

    def get_key(self, note):
        return self.map.get(note)


class LyrePlayer:
    def __init__(self, midi_file_path: str, note_key_map: NoteKeyMap,
                 start_key_combo: List[pynput.keyboard.Key], stop_key: List[pynput.keyboard.Key]):
        self.midi_file_path = midi_file_path
        self.note_key_map = note_key_map
        self.start_key_combo = start_key_combo
        self.stop_key_combo = stop_key

        self.cur_pressed_keys = set()
        self.play_task_active = False
        self.playing_event_loop = asyncio.get_event_loop()

    async def play(self):
        print('start playing')
        mid = mido.MidiFile(self.midi_file_path)
        keyboard = pynput.keyboard.Controller()

        for msg in mid.play():
            if not self.play_task_active:
                print("stop playing")
                for key in self.cur_pressed_keys.copy():
                    keyboard.release(key)
                break

            if msg.type == "note_on":
                key = self.note_key_map.get_key(msg.note)
                if key:
                    keyboard.press(key)
            elif msg.type == "note_off":
                key = self.note_key_map.get_key(msg.note)
                if key:
                    keyboard.release(key)

    def on_press(self, key):
        self.cur_pressed_keys.add(key)

        if all(key in self.cur_pressed_keys for key in self.start_key_combo):
            if not self.play_task_active:
                self.play_task_active = True
                self.playing_event_loop.call_soon_threadsafe(lambda: self.playing_event_loop.create_task(self.play()))

        elif all(key in self.cur_pressed_keys for key in self.stop_key_combo):
            if self.play_task_active:
                self.play_task_active = False

    def on_release(self, key):
        self.cur_pressed_keys.discard(key)

    def start(self):
        pynput.keyboard.Listener(on_press=self.on_press, on_release=self.on_release).start()
        self.playing_event_loop.run_forever()


if __name__ == "__main__":
    LyrePlayer(MIDI_FILE_PATH, NoteKeyMap(ROOT_NOTE), START_KEY_COMBO, STOP_KEY_COMBO).start()
