```nu
use ../cprint.nu *

let $text = open lazytests/TheSongoftheFalcon.txt
let $two_single_lines_text = r#'"High up in the mountains, a Snake crawled and lay in a damp gorge, coiled
    into a knot, staring out at the sea.'#
null
```

```nu
width-safe 20 10
```

Output:

```
10
```

```nu
$two_single_lines_text
| remove_single_nls
```

Output:

```
"High up in the mountains, a Snake crawled and lay in a damp gorge, coiled     into a knot, staring out at the sea.
```

```nu
cprint $text --keep_single_breaks --indent 4
```

Output:

```
    # The Song of the Falcon (excerpt)

    "High up in the mountains, a Snake crawled and lay in a damp gorge, coiled
    into a knot, staring out at the sea.

    "The sun was shining high in the sky, and the mountains were exhaling heat
    into the sky, and the waves were crashing below against the rocks...

    "Through the gorge, amidst darkness and splashes, a stream rushed towards
    the sea, thundering with stones...

    "Covered in white foam, gray and strong, it cut through the mountain and
    fell into the sea, howling angrily.

    "Suddenly, into that gorge where the Snake was coiled, a Falcon fell from
    the sky with a shattered chest, bloodied feathers...

    "With a short cry, it fell to the ground and beat its chest in powerless
    rage against the hard rock...

    "The Snake was frightened, slithered away swiftly, but soon understood that
    the bird had only two or three minutes of life left...

    "It crawled closer to the shattered bird and hissed directly into its eyes:

    "'So, you're dying?'

    "'Yes, I'm dying!' the Falcon answered, sighing deeply. 'I've lived a
    glorious life! I know happiness! I've fought bravely! I've seen the sky...
    You'll never see it that close! Ah, you poor thing!

    "'So what, the sky? An empty place... How could I crawl there? I'm
    perfectly fine here... warm and damp!'

    "That's how the Snake responded to the free bird and smiled inwardly at it
    for these delusions.

    "It thought: 'Fly or crawl, the end is known: everyone will lie in the
    earth, everyone will turn to dust...'

    "But the brave Falcon suddenly stirred, rose slightly, and looked around
    the gorge...

    "Water was seeping through the gray stone; it was stuffy in the dark gorge
    and smelled of decay.

    "And the Falcon cried out with sorrow and pain, gathering all its
    strength:

    "'Oh, if only I could rise to the sky just once more! I would press my
    enemy... to the wounds on my chest and... he would choke on my blood! Oh,
    the joy of battle!'

    "And the Snake thought: 'It must indeed be pleasant to live in the sky if
    he moans like that!'

    "And it suggested to the free bird: 'Why don't you move to the edge of the
    gorge and throw yourself down.

    "Maybe your wings will lift you, and you'll live a little longer in your
    element.'

    "The Falcon trembled, and, crying out proudly, went to the cliff, sliding
    its claws over the slimy rock.

    "It approached, spread its wings, took a deep breath, sparkled with its
    eyes, and—rolled down.

    "And like a stone, sliding down the rocks, it quickly fell, breaking its
    wings, losing its feathers...

    "The wave of the stream caught it, washed away its blood, dressed it in
    foam, and carried it into the sea.

    "And the waves of the sea crashed against the rock with a mournful roar...
    And the bird's body was nowhere to be seen in the vast sea..."

    ---

    "Lying in a ravine, the Snake pondered long about the death of a bird, about
    the passion for the sky.

    "Then he looked into that distance, which forever caresses the eyes with
    dreams of happiness.

    "'What did the deceased Falcon see in this bottomless, edgeless desert?
    Why do those like him who have died disturb the soul with their love for
    soaring in the sky? What clarity do they find there? I could have known
    all this if I had flown into the sky, even if just briefly.'

    "He spoke and acted. Coiling into a ring, he leapt into the air and flashed
    a narrow ribbon at the sun.

    "'Born to crawl—cannot fly!' Forgetting this, he fell onto the rocks but did
    not die; he laughed...

    "'So this is the charm of flights into the sky! It is in the fall! Silly
    birds! Not knowing the earth, yearning for it, they strive high into the
    sky and seek life in the scorching desert. It's empty there. There's a lot
    of light, but no food and no support for a living body. Why the pride then?
    Why the reproaches? To cover up the madness of their desires and to hide
    behind them their unworthiness for the affairs of life? Silly birds! But
    they will no longer deceive me with their talks! I know everything myself! I
    have seen the sky... I soared into it, measured it, knew the fall, but did
    not break, only now I believe in myself more strongly. Let those who cannot
    love the earth live by deception. I know the truth. And I will not believe
    their calls. Earth's creation—I live by the earth.'

    "And he curled into a ball on a rock, proud of himself.

    "The sea shone, all in bright light, and the waves fiercely hit the shore.

    "In their lion-like roar, a song about the proud bird thundered; the rocks
    trembled from their blows, the sky trembled from the fearsome song:

    "'We sing the glory to the madness of the brave!

    "The madness of the brave is the wisdom of life! Oh, brave Falcon! You
    bled in battle with enemies... But there will be a time—drops of your hot
    blood, like sparks, will flare up in the darkness of life and will ignite
    many brave hearts with a mad thirst for freedom, for light!

    "Let you have died! But in the song of the brave and the strong in spirit,
    you will always be a living example, a proud call to freedom, to light!

    "We sing a song to the madness of the brave!'"
```

```nu
cprint '' --frame '?'
```

Output:

```
???????????????????????????????????????????????????????????????????????????????

???????????????????????????????????????????????????????????????????????????????
```

```nu
cprint $text --lines_before 3 --echo
```

Output:

```

# The Song of the Falcon (excerpt)

"High up in the mountains, a Snake crawled and lay in a damp gorge, coiled into
a knot, staring out at the sea.

"The sun was shining high in the sky, and the mountains were exhaling heat
into the sky, and the waves were crashing below against the rocks...

"Through the gorge, amidst darkness and splashes, a stream rushed towards the
sea, thundering with stones...

"Covered in white foam, gray and strong, it cut through the mountain and fell
into the sea, howling angrily.

"Suddenly, into that gorge where the Snake was coiled, a Falcon fell from the
sky with a shattered chest, bloodied feathers...

"With a short cry, it fell to the ground and beat its chest in powerless rage
against the hard rock...

"The Snake was frightened, slithered away swiftly, but soon understood that the
bird had only two or three minutes of life left...

"It crawled closer to the shattered bird and hissed directly into its eyes:

"'So, you're dying?'

"'Yes, I'm dying!' the Falcon answered, sighing deeply. 'I've lived a glorious
life! I know happiness! I've fought bravely! I've seen the sky... You'll never
see it that close! Ah, you poor thing!

"'So what, the sky? An empty place... How could I crawl there? I'm perfectly
fine here... warm and damp!'

"That's how the Snake responded to the free bird and smiled inwardly at it for
these delusions.

"It thought: 'Fly or crawl, the end is known: everyone will lie in the earth,
everyone will turn to dust...'

"But the brave Falcon suddenly stirred, rose slightly, and looked around the
gorge...

"Water was seeping through the gray stone; it was stuffy in the dark gorge and
smelled of decay.

"And the Falcon cried out with sorrow and pain, gathering all its strength:

"'Oh, if only I could rise to the sky just once more! I would press my
enemy... to the wounds on my chest and... he would choke on my blood! Oh, the
joy of battle!'

"And the Snake thought: 'It must indeed be pleasant to live in the sky if he
moans like that!'

"And it suggested to the free bird: 'Why don't you move to the edge of the gorge
and throw yourself down.

"Maybe your wings will lift you, and you'll live a little longer in your
element.'

"The Falcon trembled, and, crying out proudly, went to the cliff, sliding its
claws over the slimy rock.

"It approached, spread its wings, took a deep breath, sparkled with its eyes,
and—rolled down.

"And like a stone, sliding down the rocks, it quickly fell, breaking its wings,
losing its feathers...

"The wave of the stream caught it, washed away its blood, dressed it in foam,
and carried it into the sea.

"And the waves of the sea crashed against the rock with a mournful roar... And
the bird's body was nowhere to be seen in the vast sea..."

---

"Lying in a ravine, the Snake pondered long about the death of a bird, about the
passion for the sky.

"Then he looked into that distance, which forever caresses the eyes with dreams
of happiness.

"'What did the deceased Falcon see in this bottomless, edgeless desert? Why do
those like him who have died disturb the soul with their love for soaring in the
sky? What clarity do they find there? I could have known all this if I had
flown into the sky, even if just briefly.'

"He spoke and acted. Coiling into a ring, he leapt into the air and flashed a
narrow ribbon at the sun.

"'Born to crawl—cannot fly!' Forgetting this, he fell onto the rocks but did not
die; he laughed...

"'So this is the charm of flights into the sky! It is in the fall! Silly
birds! Not knowing the earth, yearning for it, they strive high into the sky
and seek life in the scorching desert. It's empty there. There's a lot of light,
but no food and no support for a living body. Why the pride then? Why the
reproaches? To cover up the madness of their desires and to hide behind them
their unworthiness for the affairs of life? Silly birds! But they will no longer
deceive me with their talks! I know everything myself! I have seen the sky...
I soared into it, measured it, knew the fall, but did not break, only now I
believe in myself more strongly. Let those who cannot love the earth live by
deception. I know the truth. And I will not believe their calls. Earth's
creation—I live by the earth.'

"And he curled into a ball on a rock, proud of himself.

"The sea shone, all in bright light, and the waves fiercely hit the shore.

"In their lion-like roar, a song about the proud bird thundered; the rocks
trembled from their blows, the sky trembled from the fearsome song:

"'We sing the glory to the madness of the brave!

"The madness of the brave is the wisdom of life! Oh, brave Falcon! You bled in
battle with enemies... But there will be a time—drops of your hot blood, like
sparks, will flare up in the darkness of life and will ignite many brave hearts
with a mad thirst for freedom, for light!

"Let you have died! But in the song of the brave and the strong in spirit, you
will always be a living example, a proud call to freedom, to light!

"We sing a song to the madness of the brave!'"
```
