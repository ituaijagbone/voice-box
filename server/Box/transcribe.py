#!venv/bin/env python3

import speech_recognition as sr
import evernote.edam.type.ttypes as Types
import dropbox
import re
import os

# for now obtain path to file.
# once transcription works, move file to Dropbox

from evernote.api.client import EvernoteClient

WIT_AI_KEY = "Q2DIPNXDSFONVA7NO4G363RDKZP5XD3C"  # Wit.ai key
IBM_USERNAME = "6501f0a1-2038-4da9-8646-1ca8fc9fd8a7"  # IBM Speech to Text username
IBM_PASSWORD = "APPQZUcylzG7"  # IBM Speech to Text password
EVERNOTE_TOKEN = "S=s1:U=91d86:E=15924f9e101:C=151cd48b140:P=1cd:A=en-devtoken:V=2:H=d4ec01bb0cd49296d3b1f0d60f8d7979"
DROPBOX_TOKEN = "Cd7EqJCbv_MAAAAAAAAUQdD0MWNTSKDQWeWc-V-WRuPZFXjMizuAtLvODjHuZpVC"

# speech recognizer
r = sr.Recognizer()

# evernote setup
evernote_client = EvernoteClient(token=EVERNOTE_TOKEN, sandbox=True)
note_store = evernote_client.get_note_store()
NOTEBOOK_TITLE = "Voice Box"

# dropbox setup
dbx = dropbox.Dropbox(DROPBOX_TOKEN)
DROPBOX_FOLDER = "My Voice Box"
DROPBOX_SUB_FOLDER = "voices"

# audio storage setup
STORAGE_PATH = "/tmp"


def speech_to_text(filename):
    """
    Transcribe speech to text. Using some API. Not sure which of the APIs to choose
    :param filename: audio file
    :return: transcribed text
    """
    wav_file = os.path.join(os.path.realpath(STORAGE_PATH), filename)

    # use filename as audio source
    with sr.WavFile(wav_file) as source:
        audio = r.record(source)  # read the entire WAV file

    # recognize speech using Google Speech Recognition
    try:
        print("Google Speech Recognition " + r.recognize_google(audio))
    except sr.UnknownValueError:
        print("Google Speech Recognition could not understand audio")
        return 1, "Google Speech Recognition could not understand audio"
    except sr.RequestError as e:
        print("Could not request from Google Speech Recognition service {0}".format(e))
        return 2, "Could not request from Google Speech Recognition service {0}".format(e)

    # recognize speech using WIT.ai Recognition
    try:
        print("WIT.ai " + r.recognize_wit(audio, key=WIT_AI_KEY))
    except sr.UnknownValueError:
        print("WIT.ai could not understand audio")
        return 1, "WIT.ai could not understand audio"
    except sr.RequestError as e:
        print("Could not request from WIT.ai service {0}".format(e))
        return 2, "Could not request from WIT.ai service {0}".format(e)

    # recognize speech using IBM Watson
    try:
        note = r.recognize_ibm(audio, username=IBM_USERNAME, password=IBM_PASSWORD)
        print("IBM Watson " + note)
        return 0, note
    except sr.UnknownValueError:
        print("IBM Watson could not understand audio")
        return 1, "IBM Watson could not understand audio"
    except sr.RequestError as e:
        print("Could not request from IBM Watson service {0}".format(e))
        return 2, "Could not request from IBM Watson service {0}".format(e)


def trans(x):
    """
    Transform first character of string to uppercase
    :param x: string
    :return: string where first character of string is in uppercase
    """
    return x.capitalize()


def annotate_text(text):
    """
    Annotate transcribed text. For every 'hash tag' and 'stop'(or '.') replace with modified substring, prefixing
    substring with '@'. Where modified substring is words starting after 'tag' up to word before 'stop' or '.' such
    that space between words in substring is closed and every character after a space is turned to uppercase. If 'stop'
    or '.' isn't provided use till end of string.
    :param text:
    :return: annotated text
    """
    search_obj = re.search(r'hash tag', text)
    count = 1
    while search_obj:
        start, end = search_obj.span()
        stop = text.find("stop")
        # if there is no stop, can we use the nearest full stop to end
        if stop == -1:
            stop = text.find(".", end+1)
            if stop == -1:
                stop = len(text)
        # if there is none use the length of the text
        temp = text[end:stop]
        temp = temp.strip()
        temp = temp.split(" ")
        temp = map(trans, temp)
        temp = "@" + "".join(temp)
        # print(temp)
        text = text[:start] + temp + text[stop + 4:]
        search_obj = re.search(r'hash tag', text)
        print(text)
        if count > 3:
            print(count)
            break
        count += 1
    return text


def add_to_evernote(text):
    """
    Add text to Voice Box notebook
    :param text: transcribed text
    :return: none
    """
    note = Types.Note()
    note.title = text[0:10].strip()
    note.content = '<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE en-note SYSTEM ' \
                   '"http://xml.evernote.com/pub/enml2.dtd">'
    note.content += '<en-note>' + text + '</en-note>'

    # get notebook, if it doesn't exist create it
    note.guid = find_evernote_notebook()
    note = note_store.createNote(note)


def find_evernote_notebook():
    """
    Return the guid of Voice Box notebook. If the notebook does not exist, create it
    :return: guid of the Voice Boc
    """
    notebooks = note_store.listNotebooks()

    for n in notebooks:
        if n.name.lower() == NOTEBOOK_TITLE.lower():
            return n.guid

    return create_evernote_notebook()


def create_evernote_notebook():
    """
    Create the Voice Box notebook in evernote
    :return: guid of the Voice Box
    """
    notebook = Types.Notebook()
    notebook.name = NOTEBOOK_TITLE
    notebook = note_store.createNotebook(notebook)

    return notebook.guid


def upload_audio_to_dropbox(name):
    """
    Upload audio to dropbox
    :param name: name of audio file
    :return: FileMetaData
    """
    dropbox_path = '/%s/%s' % (DROPBOX_SUB_FOLDER, name)
    full_name = os.path.join(STORAGE_PATH, name)

    with open(full_name, 'rb') as f:
        data = f.read()
    try:
        res = dbx.files_upload(data, dropbox_path, mute=True)
    except dropbox.exceptions.ApiError as err:
        print('*** API error', err)
        return None
    print('uploaded as', res.name.encode('utf8'))
    return res


if __name__ == "__main__":
    t = "Hello we are testing hash tag song stop hash tag no longer slaves to fear by bethel music ."
    # result = annotate_text(t)
    # add_to_evernote(t)
    # file_metadata = upload_audio_to_dropbox('test.wav')
    status, note = speech_to_text("l_12-02-16_173711.wav")
    if status == 0:
        print("annotation: {}".format(annotate_text(note)))
    # print("file metadata".format(file_metadata))
