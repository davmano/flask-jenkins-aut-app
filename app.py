from flask import Flask, request, jsonify, render_template
from prometheus_flask_exporter import PrometheusMetrics
from prometheus_client import Counter, Gauge

app = Flask(__name__)
metrics = PrometheusMetrics(app, group_by='endpoint')

# Prometheus metrics
notes_created = Counter('notes_created_total', 'Total notes created')
notes_deleted = Counter('notes_deleted_total', 'Total notes deleted')
notes_gauge = Gauge('notes_in_memory', 'Current number of notes in memory')

# In-memory notes store (replace with DB for production)
notes = []

@app.route("/")
def index():
    return render_template("index.html", notes=notes)

@app.route("/notes", methods=["POST"])
def create_note():
    data = request.json
    content = data.get("content")
    if not content:
        return jsonify({"error": "Note content required"}), 400

    notes.append(content)
    notes_created.inc()
    notes_gauge.set(len(notes))

    return jsonify({"message": "Note created", "notes": notes}), 201

@app.route("/notes", methods=["GET"])
def list_notes():
    return jsonify({"notes": notes})

@app.route("/notes/<int:note_id>", methods=["DELETE"])
def delete_note(note_id):
    if note_id < 0 or note_id >= len(notes):
        return jsonify({"error": "Note not found"}), 404

    notes.pop(note_id)
    notes_deleted.inc()
    notes_gauge.set(len(notes))

    return jsonify({"message": "Note deleted", "notes": notes})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
