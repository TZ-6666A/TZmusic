import { HdsNavigation, HdsTabs, HdsTabsController, hdsMaterial } from '@kit.UIDesignKit'
import { Liked } from './Liked'
import { KGe } from './KGe'
import { Mine } from './Mine'
import { Recommend } from './Recommend'
import { playerManager } from '../utils/AvPlayerManager'

interface TabItem {
  text: string
  icon: ResourceStr
}

@Builder
export function LayoutBuilder() {
  Layout()
}

@ComponentV2
struct Layout {
  @Local private currentIndex: number = 0
  @Local private materialLevel: hdsMaterial.MaterialLevel = hdsMaterial.MaterialLevel.SMOOTH
  private tabsController: HdsTabsController = new HdsTabsController()
  private pathStack: NavPathStack = new NavPathStack()
  private tabData: TabItem[] = [
    { text: '\u5927\u5385', icon: $r('app.media.dhzhuye') },
    { text: 'K\u6b4c', icon: $r('app.media.dhkge') },
    { text: '\u559c\u6b22', icon: $r('app.media.dhxihuan') },
    { text: '\u4e2a\u4eba', icon: $r('app.media.dhwode') }
  ]

  aboutToAppear(): void {
    playerManager.bindContext(getContext(this))
  }

  build() {
    NavDestination() {
      HdsNavigation() {
        HdsTabs({ controller: this.tabsController, index: this.currentIndex }) {
          ForEach(this.tabData, (item: TabItem, index: number) => {
            TabContent() {
              if (index === 0) {
                Recommend()
              } else if (index === 1) {
                KGe()
              } else if (index === 2) {
                Liked()
              } else {
                Mine()
              }
            }
            .tabBar(new BottomTabBarStyle(item.icon, item.text))
          })
        }
        .barOverlap(true)
        .scrollable(false)
        .vertical(false)
        .barPosition(BarPosition.End)
        .barFloatingStyle({
          barBottomMargin: 20,
          systemMaterialEffect: {
            materialType: hdsMaterial.MaterialType.ADAPTIVE,
            materialLevel: this.materialLevel
          }
        })
        .onChange((index: number) => {
          this.currentIndex = index
        })
      }
      .width('100%')
      .height('100%')
      .mode(NavigationMode.Stack)
      .hideBackButton(true)
      .hideTitleBar(true)
      .ignoreLayoutSafeArea(
        [LayoutSafeAreaType.SYSTEM],
        this.currentIndex === 3 ?
          [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM] :
          [LayoutSafeAreaEdge.BOTTOM]
      )
    }
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack
    })
  }
}
