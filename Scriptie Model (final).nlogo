breed [bots bot]
breed [humans human]
turtles-own [narcissism free-patches check news-list]
humans-own [POS DES consc pers]
globals [sample-size spread false-pos false-neg fakenews density]


;Runs 50 simulations for a certain algorithm
;Exports the data for each simulation
to run-it
  set sample-size 0
  while [sample-size < 50][
    setup
    while[length spread < 50][
      check-news
    ]
    export
    set sample-size sample-size + 1
  ]
end

;Start a new simulation
;Resets the entire model except the sample-size variable,
; to facilitate running many simulations in a row
to setup
  clear-ticks
  clear-turtles
  clear-patches
  clear-drawing
  clear-all-plots
  clear-output

  set density 2.36
  set spread []
  set false-pos []
  set false-neg []
  set fakenews 1.7

  ;Initialise human agents
  create-humans 1000 [
    set narcissism random-normal 3.37 1.08
    set POS random-normal 4.69 0.8
    set DES random-normal 3.49 0.98
    set consc random-normal 4.14 0.99
    set shape "square"
    set color black
    set check false
    set pers 0
    set news-list []
    move-to one-of patches
  ]

  ;Initialise bot agents
  create-bots 50 [
    set narcissism 0
    set shape "square"
    set color black
    set check false
    set news-list []
    move-to one-of patches
  ]

  ;Initialise connections between agents
  let i 0
  while [i < density][
    ask turtles [
      let fr_count ( 2.36 + 0.354 * narcissism )
      if random ( density ) > density - log fr_count 2
      [
        create-links-with n-of 1 other turtles
      ]
    ]
    set i i + 1
  ]

  ;Choose 2 random agents to be the first spreaders
  ask n-of 2 turtles[
    set color green
    set check true
    set news-list lput 1 news-list
  ]

  reset-ticks
end

to check-news
  ;If 50 iterations have been run, end this simulation
  if length spread >= 50[
    export
    stop
  ]
  ;If the simulation has had enough cycles such that the news has spread as far as possible,
  ;soft reset the simulation to simulate a new fake story spreading, while keeping the record of who spread fake news in previous iterations
  if ticks > 30
  [
    set spread lput count turtles with [color = green] spread
    set false-pos lput count humans with [color = white] false-pos
    set false-neg lput count bots with [color != white] false-neg

    ask turtles [
      ;If an agent has not been flagged, reset their attitude so that they are ready to receive a new story
      if color != white[
        set color black
        set check false
      ]
    ]

    ;Choose 2 random agents to be the first spreaders
    ask n-of 2 turtles with [color != white][
      set color green
      set check true
      set news-list lput 1 news-list
    ]
    reset-ticks
  ]

  ;If an agent is linked with an agent that shared fake news, and they themselves
  ;have not yet been exposed to this story, they will see the story and decide whether or not to share it,
  ask turtles with [ any? link-neighbors with [color = green] and check = false]
  [
    ;Runs the bot detection algorithm for this agent
    ifelse (bot-detect news-list = false) and (color != white)
    [
      ;For humans, run the calculation that determines if they will share
      ifelse breed = humans [
        set pers ((2.663 + -0.266 * POS) + (7.036 + -0.576 * consc + -0.391 * DES))
        ifelse fakenews * random 5 > ( 5 - log pers 2)
        [
          set color green
          set check true
          set news-list lput 1 news-list
        ]
        [
          set color red
          set check true
          set news-list lput 0 news-list
        ]
      ]

      ;For bots, always share
      [
        set color green
        set check true
        set news-list lput 1 news-list
      ]
    ]
    [set color white]
  ]

  tick
end

;Determines whether a given user is a bot, based on their post history
to-report bot-detect [n-list]
  if length n-list >= 20[
    let list-avg []
    let i 0

    ;List the likelihood of sharing a story for each agent in the network
    while [i < count turtles]
    [
      if (length [news-list] of turtle i > 0) and ([color] of turtle i != white)
      [
        set list-avg lput (mean [news-list] of turtle i) list-avg
      ]
      set i i + 1
    ]

    let list-mean mean list-avg
    let list-sd standard-deviation list-avg

    ;The limit is the maximum amount of stories an agent can share before it is considered suspicious
    let limit list-mean + 2 * list-sd

    ;If an agent has shared more than the limit, flag them as a bot
    if mean n-list > limit[
      report true
    ]
  ]

  report false
end

;Export spread, false-pos, false-neg for each iteration of the simulation
to export
  file-open (word "Data 2/data_" sample-size ".csv")
  file-print "iteration spread false-pos false-neg"
  let it 0
  while [it < 50][
    file-write it + 1
    file-write item it spread
    file-write item it false-pos
    file-write item it false-neg
    file-print ""
    set it it + 1
  ]
  file-close
end

;Output how often each human agent spreads a fake news story for each human
to graph
  file-open "dist.csv"
  let list-avg []
  let i 0
  while [i < count humans]
  [
    if (length [news-list] of human i > 0) and ([color] of human i != white)
    [
      set list-avg lput (mean [news-list] of human i) list-avg
    ]
    set i i + 1
  ]
  let j 0
  while [j < 1000][
    file-print item j list-avg
    set j j + 1
  ]
  file-close
end
@#$#@#$#@
GRAPHICS-WINDOW
258
10
695
448
-1
-1
13.0
1
10
1
1
1
0
0
0
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
9
25
72
58
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
8
76
104
109
NIL
check-news
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
11
120
74
153
check
check-news
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
14
225
77
258
NIL
run-it
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
21
287
85
320
NIL
graph
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

This model is a representation of how fake news spreads in an online social network. There are 1000 'humans' and 50 'bots'. Humans and bots have their own behaviour. Humans have larger networks than bots, while bots are more likely to share fake news than humans. The model tries to mimick the behaviour of humans based on several human personality traits. The model also includes a bot detection algorithm, that tries to find the bot accounts and exclude them from the network.

## HOW IT WORKS

At the start of each simulation, 1000 humans are created with randomly generated, normally distributed personally traits. (narcissism, conscientiousness, POS, DES) Then 50 bots are created. Based on the narcissism value (always 0 for bots) it is determined how many connections an agent should be expected to have in the network. Bots on average having significantly less connections than humans. Initially, all 1050 turtles are coloured black.

To start the simulation, 2 random turtles are selected, human or bot, and their colour is turned to green, indicating that they shared fake news. Then all turtles linked to these 2 turtles will each determine whether to also share the fake news, based on the values of conscientiousness, POS, and DES. If they decided to share, their colour is turned green, otherwise it is turned red. This process then repeats itself for all turtles that are linked to newly green-coloured turtles. Each turtle will only make this calculation once per iteration.

After 30 ticks the story has had plenty of time to spread throughout the network, so the simulation is reset to its start phase, and 2 new turtles are randomly selected to turn green, and the entire cycle repeats.

Once this cycle has happened 20 times, the bot detection algorithm has collected enoguh data and will start flagging turtles. Every time any turtle is in the process of deciding whether or not to share, the bot detection algorithm calculates if this turtle is an outlier in how often it shares. If the algorithm flags a turtle, the turtle is coloured white, and can no longer interact with the rest of the network.

Once the simulation has been run 50 times, the simulation ends.

## HOW TO USE IT

'setup' initialises all the turtles (humans and bots) and the links between them, as well as randomly picking 2 random turtles to be the first spreaders.

'check-news' ends the simulation if 50 iterations have been reached, and resets the simulation if 30 ticks have been reached within a simulation. If neither is the case, it runs the calculations of whether to share for each turtle, connected to a green turtle, that has not yet been checked, including the bot detection algorithm.

'check' puts check-news on a loop

'run-it' runs the whole process of a simulation, from setting up the simulation, to going through 50 iterations of 30 ticks each. Afterwards it exports the data from this simulations. Repeats this entire process 50 times, with 50 seperate simulations.

'graph' exports the data of how often a turtle shares fake news compared to how often it decides not to share fake news, for each human turtle. Used to gain insight into how likely people on average are to share fake news.


## RELATED MODELS

This model is heavily influenced by and sourced from the model created by Burbach et al. (2019)

## CREDITS AND REFERENCES
Burbach, L., Halbach, P., Ziefle, M., & Calero Valdez, A. (2019, June). Who shares fake	 news in online social networks?. In Proceedings of the 27th ACM Conference on User Modeling, Adaptation and Personalization (pp. 234-242).
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
