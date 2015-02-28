see true
---
    say("1: okay");
---

see false
--->
    say("2: xxx");
--->
    say("2: okay");
---

see true
--->> 1 == 0:
     say("3: xxx");
--->> 1 == 1:
     say("3: okay");
--->> 1 == 2:
     say("3: xxx");
--->>
     say("3: xxx");
---
