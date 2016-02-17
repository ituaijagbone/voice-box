from flask import Flask, jsonify, request
from werkzeug import secure_filename
from transcribe import upload_audio_to_dropbox, speech_to_text, add_to_evernote, annotate_text

import os
import sys

UPLOAD_FOLDER = '/tmp'
HOST_URL = "http://localhost:2000"

app = Flask(__name__)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

@app.route('/')
@app.route('/audio', methods=['POST'])
def transcribe_audio():
    result = {}
    if request.method == 'POST':
        print(request.files.getlist("file"))
        file = request.files.getlist("file")[0]
        if file:
            filename = 'l_' + secure_filename(file.filename)
            file.save(os.path.join(app.config['UPLOAD_FOLDER'], filename))
            file_metadata = upload_audio_to_dropbox(filename)
            print("file metadata".format(file_metadata))
            status, note = speech_to_text(filename)
            if status == 0:
                add_to_evernote(note)
                text = annotate_text(note)
                result['status'] = "success"
                result['annotation'] = text
            else:
                result['status'] = "failure"

            return jsonify(result)

    result['status'] = "failure"
    return jsonify(result)

if __name__ == '__main__':
    app.run(host="0.0.0.0", port=int("2000"), debug=True)
