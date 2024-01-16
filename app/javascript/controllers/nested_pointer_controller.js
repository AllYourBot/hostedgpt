import { Controller } from '@hotwired/stimulus'

// This handles nested "cursor-poiner" classes. Any time you have a child component which you're placing cursor-pointer on, add this controller as well so it
// does no trigger the parent as well.
//
// Within or master CSS, we extend cursor-pointer so that, not only does it make the cursor turn into a finger, but it also makes the element exhibit a smal
// visual change when it's clicked. It looks like it's being depressed inward.
//
// However, imagine the situation where we have a row which has cursor-poiner on it but at the end of the row, witwhin it, there is a delete icon. When you
// click on the delete icon it depresses inward but the whole row also depresses inward. We don't it to feel like you are trigger the full row, we just want
// it to feel like you are triggering the delete icon.
//
// If there was a way for CSS to reference parent elements, then we wouldn't need javascript to fix this. But this little bit of javascript was the only way
// I could figure out how.

export default class extends Controller {

  connect () {
    this.element.addEventListener('mouseover', (event) => this.removeParentClickable(event))
    this.element.addEventListener('mouseout', () => this.addParentClickable())
  }

  disconnect () {
    this.element.removeEventListener('mouseover', (event) => this.removeParentClickable(event))
    this.element.removeEventListener('mouseout', () => this.addParentClckable())
  }

  removeParentClickable (event) {
    this.parent = event.currentTarget.parentNode.closest('.cursor-pointer')
    this.parent.classList.remove('cursor-pointer')
  }

  addParentClickable () {
    this.parent.classList.add('cursor-pointer')
  }
}
