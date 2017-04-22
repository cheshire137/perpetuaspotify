function openModal(event) {
  event.preventDefault()

  const modalSelector = event.currentTarget.getAttribute('href')
  const modal = document.querySelector(modalSelector)
  modal.classList.add('is-active')

  const focusTarget = modal.querySelector('.js-modal-focus')
  if (focusTarget) {
    focusTarget.focus()
  }
}

function closeModal(event) {
  const modal = event.target.closest('.modal')
  modal.classList.remove('is-active')
}

function setUpModals() {
  const openLinks = document.querySelectorAll('.js-trigger-modal')
  for (let i = 0; i < openLinks.length; i++) {
    openLinks[i].addEventListener('click', openModal)
  }

  const closeLinks = document.querySelectorAll('.js-modal-close')
  for (let i = 0; i < closeLinks.length; i++) {
    closeLinks[i].addEventListener('click', closeModal)
  }
}

function onPlaylistNameKeyup(event) {
  if (event.keyCode === 27) { // Esc
    closeModal(event)
  }
}

function listenForEscape() {
  const input = document.querySelector('.js-playlist-name-input')
  if (input) {
    input.addEventListener('keyup', onPlaylistNameKeyup)
  }
}

setUpModals()
listenForEscape()
