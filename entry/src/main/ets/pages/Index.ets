//整个App的“导航入口 + 路由容器初始化页”
import { AppStorageV2 } from '@kit.ArkUI';
import { StartBuilder } from './Start';
import { LoginBuilder } from './Login';
import { LayoutBuilder } from './Layout';
import { PlayBuilder } from './Play';
import { PlayListBuilder } from './PlayList';
import { RecordBuilder } from './Record';
import { SingerDetailBuilder } from './SingerDetail';
import { HistoryKGeBuilder } from './HistoryKGe';
import { ProfileEditBuilder } from './ProfileEdit';
import { ListenLevelBuilder } from './ListenLevel';

@Entry
@ComponentV2
struct Index {
  //pathStack : NavPathStack = new NavPathStack();
  pathStack : NavPathStack = AppStorageV2.connect(NavPathStack,'navStack',()=>new NavPathStack())!

  // 显式路由表：所有 pushPathByName 的页面都在这里注册
  @Builder
  routeMap(name: string, param: Object) {
    if (name === 'Start') {
      StartBuilder()
    } else if (name === 'Login') {
      LoginBuilder()
    } else if (name === 'Layout') {
      LayoutBuilder()
    } else if (name === 'Play') {
      PlayBuilder()
    } else if (name === 'PlayList') {
      PlayListBuilder()
    } else if (name === 'Record') {
      RecordBuilder()
    } else if (name === 'SingerDetail') {
      SingerDetailBuilder()
    } else if (name === 'HistoryKGe') {
      HistoryKGeBuilder()
    } else if (name === 'ProfileEdit') {
      ProfileEditBuilder()
    } else if (name === 'ListenLevel') {
      ListenLevelBuilder()
    }
  }

  build() {
    //入参，添加this.pathStack就是绑定pathstack，所有路由操作都通过 this.pathStack 完成
    Navigation(this.pathStack){
    }
    .navDestination(this.routeMap)
    .onAppear(() => {
      this.pathStack.pushPathByName("Start", null, false);
    })
    .hideNavBar(true) // 不会把自己放到控制跳转的对象里面 → 点返回的时候不会返回到这个导航页 //隐藏标题栏
  }
}
