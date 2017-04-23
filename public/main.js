function resizeOpenModal() {
  const openModal = document.querySelector('.modal.is-active')
  if (!openModal) {
    return
  }

  const modalBody = openModal.querySelector('.modal-card-body')
  if (modalBody) {
    const padding = 20
    let height = window.innerHeight - padding
    const modalFoot = openModal.querySelector('.modal-card-foot')
    if (modalFoot) {
      const footRect = modalFoot.getBoundingClientRect()
      height -= footRect.height
    }
    if (modalBody.classList.contains('has-tabs')) {
      const activeTab = modalBody.querySelector('.tab.is-active')
      const rect = activeTab.getBoundingClientRect()
      height -= rect.top
      activeTab.style.maxHeight = `${height}px`
    } else {
      const rect = modalBody.getBoundingClientRect()
      height -= rect.top
      modalBody.style.maxHeight = `${height}px`
    }
  }
}

function openModal(event) {
  event.preventDefault()

  const modalSelector = event.currentTarget.getAttribute('href')
  const modal = document.querySelector(modalSelector)
  modal.classList.add('is-active')

  const focusTarget = modal.querySelector('.js-modal-focus')
  if (focusTarget) {
    focusTarget.focus()
  }

  resizeOpenModal()
}

function closeModal(event) {
  const modal = event.target.closest('.modal')
  modal.classList.remove('is-active')
}

function setUpModals(container) {
  const openLinks = container.querySelectorAll('.js-trigger-modal')
  for (let i = 0; i < openLinks.length; i++) {
    openLinks[i].addEventListener('click', openModal)
  }

  const closeLinks = container.querySelectorAll('.js-modal-close')
  for (let i = 0; i < closeLinks.length; i++) {
    closeLinks[i].addEventListener('click', closeModal)
  }
}

function closeModalOnEscape() {
  if (document.querySelector('.modal')) {
    window.addEventListener('keyup', function(event) {
      const openModal = document.querySelector('.modal.is-active')
      if (!openModal) {
        return
      }
      if (event.keyCode === 27) { // Esc
        openModal.classList.remove('is-active')
      }
    })
  }
}

function dismissNotification(event) {
  const notification = event.target.closest('.notification')
  notification.remove()
}

function setUpNotificationDismissals() {
  const buttons = document.querySelectorAll('.js-hide-notification')
  for (let i = 0; i < buttons.length; i++) {
    buttons[i].addEventListener('click', dismissNotification)
  }
}

function toggleTrackInfo(event) {
  const button = event.currentTarget
  button.blur()

  const container = button.closest('.js-track-info-container')
  const trackInfo = container.querySelector('.js-track-info')
  const isVisible = trackInfo.classList.contains('is-visible')

  const allTrackInfos = document.querySelectorAll('.js-track-info.is-visible')
  for (let i = 0; i < allTrackInfos.length; i++) {
    allTrackInfos[i].classList.remove('is-visible')
  }

  trackInfo.classList.toggle('is-visible', !isVisible)
}

function setUpTrackInfo(container) {
  const buttons = container.querySelectorAll('.js-track-info-toggle')
  for (let i = 0; i < buttons.length; i++) {
    buttons[i].addEventListener('click', toggleTrackInfo)
  }
}

function toggleSubmitButton(button, disabled) {
  button.classList.toggle('is-disabled', disabled)
  button.classList.toggle('is-loading', disabled)
}

function setUpSubmitButtons(container) {
  const buttons = container.querySelectorAll('form .js-submit-button')
  for (let i = 0; i < buttons.length; i++) {
    buttons[i].addEventListener('click', function(event) {
      toggleSubmitButton(event.currentTarget, true)
    })
  }
}

function resizeModalOnWindowResize() {
  if (!document.querySelector('.modal')) {
    return
  }
  window.addEventListener('resize', resizeOpenModal)
}

function switchTab(event) {
  event.preventDefault()
  const link = event.currentTarget
  const li = link.closest('li')
  const tabList = li.closest('.tabs')
  const activeLi = tabList.querySelector('li.is-active')
  if (activeLi) {
    activeLi.classList.remove('is-active')
  }
  li.classList.add('is-active')

  const tab = document.querySelector(link.getAttribute('href'))

  if (tab) {
    const activeTab = tab.parentNode.querySelector('.tab.is-active')
    if (activeTab) {
      activeTab.classList.remove('is-active')
    }
    tab.classList.add('is-active')
  }

  resizeOpenModal()
}

function setUpTabs(container) {
  const tabLinks = container.querySelectorAll('.js-switch-tab')
  for (let i = 0; i < tabLinks.length; i++) {
    tabLinks[i].addEventListener('click', switchTab)
  }
}

function onRemoteFormSubmit(event) {
  event.preventDefault()

  const form = event.target
  const button = form.querySelector('button[type=submit]')
  toggleSubmitButton(button, true)

  const req = new XMLHttpRequest()
  req.open(form.method, form.action)

  req.onload = function() {
    if (req.status === 200) {
      const targetID = form.getAttribute('data-target-id')
      const target = document.getElementById(targetID)
      target.innerHTML = req.responseText

      toggleSubmitButton(button, false)
      closeModal(event)
      setUpModals(target)
      setUpRemoteForms(target)
      setUpTrackInfo(target)
      setUpSubmitButtons(target)
      setUpTabs(target)
      setUpSeedCountRemaining(target)
    } else {
      console.error(req.status, req.statusText)
    }
  }

  req.send(new FormData(form))
}

function setUpRemoteForms(container) {
  const forms = container.querySelectorAll('.js-remote-form')
  for (let i = 0; i < forms.length; i++) {
    forms[i].addEventListener('submit', onRemoteFormSubmit)
  }
}

function onSeedChange(container, event) {
  const remainingEl = container.querySelector('.js-seed-count-remaining')
  const maxCount = parseInt(remainingEl.getAttribute('data-max'), 10)
  const seedCheckboxes = container.querySelectorAll('.js-seed-checkbox')
  const selectedCount = container.querySelectorAll('.js-seed-checkbox:checked').length

  const remainingCount = maxCount - selectedCount
  const suffix = remainingEl.getAttribute('data-suffix')
  remainingEl.textContent = `${remainingCount} ${suffix}`

  const shouldDisable = remainingCount <= 0
  for (let i = 0; i < seedCheckboxes.length; i++) {
    const checkbox = seedCheckboxes[i]
    checkbox.disabled = shouldDisable && !checkbox.checked
  }
}

function setUpSeedCountRemaining(container) {
  const seedCheckboxes = container.querySelectorAll('.js-seed-checkbox')
  for (let i = 0; i < seedCheckboxes.length; i++) {
    const checkbox = seedCheckboxes[i]
    checkbox.addEventListener('change', function(event) {
      onSeedChange(container, event)
    })
  }
}

closeModalOnEscape()
resizeModalOnWindowResize()
setUpNotificationDismissals()

setUpModals(document)
setUpTrackInfo(document)
setUpRemoteForms(document)
setUpSubmitButtons(document)
setUpTabs(document)
setUpSeedCountRemaining(document)
