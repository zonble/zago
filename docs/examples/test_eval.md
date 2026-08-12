```logo
NL NL NL NL
MOVE UP MOVE UP MOVE UP
REPEAT 10 [BOX :#]
```

```logo
NL
TABLE 2 2
```

```logo
NL
REPEAT 10 [TYPE "- " TYPE :# NL]
```

```logo
NL NL NL NL
MOVE UP MOVE UP MOVE UP
PD
REPEAT 10 [FD 2 IFELSE :# % 2 == 0 [LEFT][RIGHT]]
```

```logo
PU
PD
FD 10
```