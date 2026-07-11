import { preferences } from '@kit.ArkData'
import { defaultReviews, ReviewItem, reviewSongs } from '../data/reviewData'

const REVIEW_STORE_NAME = 'review_store'
const KEY_REVIEWS = 'reviews'

interface StoredReviewItem {
  name: string
  author: string
  comment: string
  imgIndex: number
}

function makeReviewItem(name: string, author: string, comment: string, img: ResourceStr): ReviewItem {
  return {
    name: name,
    author: author,
    comment: comment,
    img: img
  }
}

function makeStoredReviewItem(name: string, author: string, comment: string, imgIndex: number): StoredReviewItem {
  return {
    name: name,
    author: author,
    comment: comment,
    imgIndex: imgIndex
  }
}

@ObservedV2
export class ReviewStore {
  @Trace reviews: ReviewItem[] = defaultReviews
  private prefs?: preferences.Preferences
  private ready: boolean = false

  async init(context: Context): Promise<void> {
    if (this.ready) return
    try {
      this.prefs = await preferences.getPreferences(context, REVIEW_STORE_NAME)
      const value = await this.prefs.get(KEY_REVIEWS, '')
      if (typeof value === 'string' && value.length > 0) {
        const stored: StoredReviewItem[] = JSON.parse(value)
        const nextReviews: ReviewItem[] = []
        stored.forEach((item: StoredReviewItem) => {
          const img = reviewSongs[item.imgIndex]?.img || defaultReviews[0].img
          nextReviews.push(makeReviewItem(item.name, item.author, item.comment, img))
        })
        this.reviews = nextReviews
      }
      this.ready = true
    } catch (err) {
      console.error('ReviewStore init failed: ' + JSON.stringify(err))
      this.reviews = defaultReviews
      this.ready = true
    }
  }

  addReview(song: ReviewItem, comment: string): void {
    const text = comment.trim()
    if (!text) return
    const nextReviews: ReviewItem[] = [makeReviewItem(song.name, song.author, text, song.img)]
    this.reviews.forEach((item: ReviewItem) => {
      nextReviews.push(item)
    })
    this.reviews = nextReviews
    void this.save()
  }

  deleteReview(index: number): void {
    if (index < 0 || index >= this.reviews.length) return
    const nextReviews: ReviewItem[] = []
    this.reviews.forEach((item: ReviewItem, itemIndex: number) => {
      if (itemIndex !== index) {
        nextReviews.push(item)
      }
    })
    this.reviews = nextReviews
    void this.save()
  }

  private async save(): Promise<void> {
    if (!this.prefs) return
    try {
      const stored: StoredReviewItem[] = []
      this.reviews.forEach((item: ReviewItem) => {
        const imgIndex = Math.max(0, reviewSongs.findIndex((song: ReviewItem) => {
          return song.name === item.name && song.author === item.author
        }))
        stored.push(makeStoredReviewItem(item.name, item.author, item.comment, imgIndex))
      })
      await this.prefs.put(KEY_REVIEWS, JSON.stringify(stored))
      await this.prefs.flush()
    } catch (err) {
      console.error('ReviewStore save failed: ' + JSON.stringify(err))
    }
  }
}
