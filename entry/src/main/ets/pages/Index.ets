//整个App的“导航入口 + 路由容器初始化页”
import { AppStorageV2 } from '@kit.ArkUI';

@Entry
@ComponentV2
struct Index {
  //pathStack : NavPathStack = new NavPathStack();
  pathStack : NavPathStack = AppStorageV2.connect(NavPathStack,'navStack',()=>new NavPathStack())!

  build() {
    //入参，添加this.pathStack就是绑定pathstack，所有路由操作都通过 this.pathStack 完成
    Navigation(this.pathStack){
    }.onAppear(() => {
      this.pathStack.pushPathByName("Start", null, false);
    })
    .hideNavBar(true) // 不会把自己放到控制跳转的对象里面 → 点返回的时候不会返回到这个导航页 //隐藏标题栏
  }
}