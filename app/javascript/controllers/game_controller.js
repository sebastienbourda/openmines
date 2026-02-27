// app/javascript/controllers/game_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { id: Number }

  reveal(event) {
    const x = event.currentTarget.dataset.x
    const y = event.currentTarget.dataset.y

    fetch(`/games/${this.idValue}/reveal`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
      },
      body: JSON.stringify({ x, y })
    })
  }
}
