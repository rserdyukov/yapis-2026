functor
import
   System
   Application
define
   X Y Started
   thread
      Started = unit
      Y = X + 1
   end
   {Wait Started}
   {System.showInfo "before binding"}
   X = 41
   {Wait Y}
   {System.show Y}
   {Application.exit 0}
end
