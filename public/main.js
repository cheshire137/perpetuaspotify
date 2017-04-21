function openModal(event) {
  const modalSelector = event.currentTarget.getAttribute('href')
  const modal = document.querySelector(modalSelector)
  modal.classList.add('is-active')
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

  const closeLinks = document.querySelectorAll('.modal-close')
  for (let i = 0; i < closeLinks.length; i++) {
    closeLinks[i].addEventListener('click', closeModal)
  }
}

setUpModals()
