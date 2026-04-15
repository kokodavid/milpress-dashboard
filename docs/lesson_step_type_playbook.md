# Lesson Step Types — Frontend Integration Playbook

> This document describes all 15 lesson step types in the Milpress platform. Each step is stored as a row in the `lesson_steps` table with a `config` JSONB column. The shape of `config` is fully defined per step type below.
>
> **Intended audience:** Frontend developers integrating the lesson player.

---

## Lesson Step Row Structure

Every lesson step, regardless of type, shares the following outer fields:

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | `string (uuid)` | yes | Auto-generated |
| `lesson_id` | `string (uuid)` | yes | Parent lesson |
| `step_key` | `string` | yes | Unique key within the lesson (e.g. `"intro_a"`) |
| `step_type` | `string (enum)` | yes | See full list below |
| `position` | `int` | yes | 1-based ordering within the lesson |
| `required` | `bool` | yes | Whether the learner must complete this step to progress |
| `config` | `object` | yes | Shape is specific to `step_type` |

### `step_type` values

```
introduction
demonstration
practice
assessment
blending
sound_discrimination
sound_item_matching
guided_reading
practice_game
sound_presence_check
missing_letters
matching_words
word_reading
sentence_reading
mini_story_card
```

---

## Step Types

---

### 1. `introduction`

**Purpose:** Introduces a new letter or sound to the learner. Displays the character, provides audio at multiple playback speeds, an SVG stroke guide, and a practice tip.

#### Config shape

```json
{
  "title": "Letter A",
  "display_text": "A",
  "audio": {
    "base_url": "https://cdn.example.com/audio/a",
    "speed_variants": {
      "0.5x": "https://cdn.example.com/audio/a_0.5x.mp3",
      "1x":   "https://cdn.example.com/audio/a_1x.mp3",
      "1.5x": "https://cdn.example.com/audio/a_1.5x.mp3"
    }
  },
  "how_to_svg_url": "https://cdn.example.com/svg/a_stroke.svg",
  "practice_tip": {
    "text": "Say /a/ as in apple",
    "audio_url": "https://cdn.example.com/audio/tip_a.mp3"
  }
}
```

#### Fields

| Field | Type | Required | Notes |
|---|---|---|---|
| `title` | `string` | yes | Display title of the step |
| `display_text` | `string` | yes | The letter or sound being introduced |
| `audio` | `object` | no | Container for audio assets |
| `audio.base_url` | `string` | no | Base path for audio assets |
| `audio.speed_variants` | `object` | no | Keys: `"0.5x"`, `"1x"`, `"1.5x"` — each a URL string |
| `how_to_svg_url` | `string` | no | SVG animation showing stroke order |
| `practice_tip` | `object` | no | Hint shown alongside the introduction |
| `practice_tip.text` | `string` | no | Tip text |
| `practice_tip.audio_url` | `string` | no | Audio for the tip |

---

### 2. `demonstration`

**Purpose:** Shows the learner how something is done via a sequence of images, with optional completion feedback.

#### Config shape

```json
{
  "title": "Watch and learn",
  "image_urls": [
    "https://cdn.example.com/images/demo1.png",
    "https://cdn.example.com/images/demo2.png"
  ],
  "feedbackTitle": "Great job!",
  "feedbackBody": "You watched the full demonstration."
}
```

#### Fields

| Field | Type | Required | Notes |
|---|---|---|---|
| `title` | `string` | yes | Step title |
| `image_urls` | `string[]` | no | Ordered list of image URLs to display |
| `feedbackTitle` | `string` | no | Title shown after the learner completes the step |
| `feedbackBody` | `string` | no | Body text shown after completion |

---

### 3. `practice`

**Purpose:** The learner practises a list of items (letters, words, or pictures) with an optional instructional tip.

#### Config shape

```json
{
  "title": "Practice the sound",
  "items": [
    {
      "label": "apple",
      "image_url": "https://cdn.example.com/images/apple.png",
      "sound_url": "https://cdn.example.com/audio/apple.mp3"
    },
    {
      "label": "ant",
      "image_url": "https://cdn.example.com/images/ant.png",
      "sound_url": "https://cdn.example.com/audio/ant.mp3"
    }
  ],
  "tip": {
    "text": "Touch each picture and say the word",
    "sound_url": "https://cdn.example.com/audio/tip_practice.mp3"
  }
}
```

#### Fields

| Field | Type | Required | Notes |
|---|---|---|---|
| `title` | `string` | yes | Step title |
| `items` | `object[]` | yes, min 1 | List of practice items |
| `items[].label` | `string` | no | Text label for the item |
| `items[].image_url` | `string` | no | Image for the item |
| `items[].sound_url` | `string` | no | Audio played when the item is tapped |
| `tip` | `object` | no | Optional instructional hint |
| `tip.text` | `string` | no | Tip text |
| `tip.sound_url` | `string` | no | Audio for the tip |

---

### 4. `assessment`

**Purpose:** A multiple-choice question used to assess learner knowledge. Exactly one option must be marked correct.

#### Config shape

```json
{
  "title": "Which picture starts with /a/?",
  "prompt": "Which picture starts with /a/?",
  "sound_instruction_url": "https://cdn.example.com/audio/instruction.mp3",
  "options": [
    {
      "label": "apple",
      "image_url": "https://cdn.example.com/images/apple.png",
      "is_correct": true
    },
    {
      "label": "banana",
      "image_url": "https://cdn.example.com/images/banana.png",
      "is_correct": false
    },
    {
      "label": "cat",
      "image_url": "https://cdn.example.com/images/cat.png",
      "is_correct": false
    }
  ]
}
```

#### Fields

| Field | Type | Required | Notes |
|---|---|---|---|
| `title` | `string` | yes | Step title |
| `prompt` | `string` | yes | The question text displayed to the learner |
| `sound_instruction_url` | `string` | no | Audio of the question or instruction |
| `options` | `object[]` | yes, min 1 | Answer choices |
| `options[].label` | `string` | no | Option text |
| `options[].image_url` | `string` | no | Option image |
| `options[].is_correct` | `bool` | yes | Exactly **one** option must be `true` |

---

### 5. `blending`

**Purpose:** The learner taps individual phonemes to hear them, then blends them together into a complete word.

#### Config shape

```json
{
  "title": "Blend the sounds",
  "instruction": "Tap each letter to hear its sound, then tap Blend",
  "instruction_audio_url": "https://cdn.example.com/audio/blend_instr.mp3",
  "examples": [
    {
      "word": "cat",
      "word_audio_url": "https://cdn.example.com/audio/cat.mp3",
      "phonemes": [
        {
          "label": "c",
          "audio_url": "https://cdn.example.com/audio/k.mp3",
          "highlighted": false
        },
        {
          "label": "a",
          "audio_url": "https://cdn.example.com/audio/a.mp3",
          "highlighted": true
        },
        {
          "label": "t",
          "audio_url": "https://cdn.example.com/audio/t.mp3",
          "highlighted": false
        }
      ]
    }
  ]
}
```

#### Fields

| Field | Type | Required | Notes |
|---|---|---|---|
| `title` | `string` | yes | Step title |
| `instruction` | `string` | no | On-screen instruction text |
| `instruction_audio_url` | `string` | no | Audio for the instruction |
| `examples` | `object[]` | yes, min 1 | Words to blend |
| `examples[].word` | `string` | yes | The full word |
| `examples[].word_audio_url` | `string` | yes | Audio of the fully blended word |
| `examples[].phonemes` | `object[]` | yes, min 1 | Ordered phoneme breakdown |
| `phonemes[].label` | `string` | yes | The grapheme label (e.g. `"c"`) |
| `phonemes[].audio_url` | `string` | yes | Audio of this phoneme when tapped |
| `phonemes[].highlighted` | `bool` | yes | Whether this phoneme is visually highlighted as the focus sound |

---

### 6. `sound_discrimination`

**Purpose:** The learner sees a set of image cards and identifies which ones contain a target sound.

#### Config shape

```json
{
  "title": "Find the /a/ sound",
  "title_audio_url": "https://cdn.example.com/audio/find_a.mp3",
  "target_sound": "a",
  "reference_word": "apple",
  "tip_text": "Listen carefully for the /a/ sound",
  "items": [
    {
      "title": "apple",
      "title_audio_url": "https://cdn.example.com/audio/apple.mp3",
      "image_url": "https://cdn.example.com/images/apple.png",
      "contains_target_sound": true,
      "highlighted_text": "a"
    },
    {
      "title": "dog",
      "title_audio_url": "https://cdn.example.com/audio/dog.mp3",
      "image_url": "https://cdn.example.com/images/dog.png",
      "contains_target_sound": false
    }
  ]
}
```

#### Fields

| Field | Type | Required | Notes |
|---|---|---|---|
| `title` | `string` | yes | Step title |
| `target_sound` | `string` | yes | The phoneme to listen for (e.g. `"a"`) |
| `reference_word` | `string` | yes | A reference word that contains the target sound |
| `title_audio_url` | `string` | no | Audio for the step title |
| `tip_text` | `string` | no | Optional hint shown to the learner |
| `items` | `object[]` | yes, min 1 | The image cards |
| `items[].title` | `string` | yes | Word displayed on the card |
| `items[].title_audio_url` | `string` | yes | Audio of the word |
| `items[].image_url` | `string` | yes | Image representing the word |
| `items[].contains_target_sound` | `bool` | yes | Whether this word contains the target sound |
| `items[].highlighted_text` | `string` | conditional | Required when `contains_target_sound` is `true` — the substring to highlight |

---

### 7. `sound_item_matching`

**Purpose:** The learner hears a sound or prompt and selects the item that matches. Supports multiple activities per step. Exactly one option must be correct per activity.

#### Config shape

```json
{
  "title": "Match the sound",
  "activities": [
    {
      "prompt": "Which picture has the /a/ sound?",
      "prompt_audio_url": "https://cdn.example.com/audio/prompt1.mp3",
      "content_audio_url": "https://cdn.example.com/audio/a_sound.mp3",
      "target_sound": "a",
      "tip_text": "Listen for the beginning sound",
      "options": [
        { "label": "apple", "is_correct": true },
        { "label": "ball",  "is_correct": false },
        { "label": "cup",   "is_correct": false }
      ]
    }
  ]
}
```

#### Fields

| Field | Type | Required | Notes |
|---|---|---|---|
| `title` | `string` | yes | Step title |
| `activities` | `object[]` | yes, min 1 | List of matching activities |
| `activities[].prompt` | `string` | yes | Question text shown to the learner |
| `activities[].content_audio_url` | `string` | yes | Audio of the sound being matched |
| `activities[].target_sound` | `string` | yes | The phoneme/sound string |
| `activities[].prompt_audio_url` | `string` | no | Audio of the question prompt |
| `activities[].tip_text` | `string` | no | Optional hint text |
| `activities[].options` | `object[]` | yes, min 2 | Answer choices |
| `options[].label` | `string` | yes | Option label |
| `options[].is_correct` | `bool` | yes | Exactly **one** must be `true` per activity |

---

### 8. `guided_reading`

**Purpose:** A word is decoded segment-by-segment with a phoneme-to-grapheme mapping. Each segment has its own audio. Supports multiple activities per step.

#### Config shape

```json
{
  "title": "Read the word",
  "activities": [
    {
      "instruction_text": "Let's read this word together",
      "instruction_audio_url": "https://cdn.example.com/audio/guided_instr.mp3",
      "word_text": "cat",
      "word_audio_url": "https://cdn.example.com/audio/cat.mp3",
      "segments": [
        {
          "phoneme_label": "/k/",
          "grapheme": "c",
          "audio_url": "https://cdn.example.com/audio/k.mp3",
          "is_focus": false
        },
        {
          "phoneme_label": "/æ/",
          "grapheme": "a",
          "audio_url": "https://cdn.example.com/audio/ae.mp3",
          "is_focus": true
        },
        {
          "phoneme_label": "/t/",
          "grapheme": "t",
          "audio_url": "https://cdn.example.com/audio/t.mp3",
          "is_focus": false
        }
      ]
    }
  ]
}
```

#### Fields

| Field | Type | Required | Notes |
|---|---|---|---|
| `title` | `string` | yes | Step title |
| `activities` | `object[]` | yes, min 1 | Reading activities |
| `activities[].instruction_text` | `string` | yes | On-screen instruction |
| `activities[].word_text` | `string` | yes | The full word to read |
| `activities[].word_audio_url` | `string` | yes | Audio of the complete word |
| `activities[].instruction_audio_url` | `string` | no | Audio for the instruction |
| `activities[].segments` | `object[]` | yes, min 1 | Phoneme-grapheme breakdown |
| `segments[].phoneme_label` | `string` | yes | IPA or readable label (e.g. `"/k/"`) |
| `segments[].grapheme` | `string` | yes | The letter(s) that represent this phoneme |
| `segments[].audio_url` | `string` | yes | Audio for this segment |
| `segments[].is_focus` | `bool` | yes | Marks the phoneme that is the focus of this lesson |

---

### 9. `practice_game`

**Purpose:** A timed game where the learner taps correct options to accumulate a passing score before the timer runs out.

#### Config shape

```json
{
  "title": "Sound Game",
  "instruction_text": "Tap all the pictures that start with /a/",
  "instruction_audio_url": "https://cdn.example.com/audio/game_instr.mp3",
  "target_sound": "a",
  "duration_seconds": 30,
  "passing_score": 3,
  "options": [
    {
      "title": "apple",
      "image_url": "https://cdn.example.com/images/apple.png",
      "audio_url": "https://cdn.example.com/audio/apple.mp3",
      "is_correct": true
    },
    {
      "title": "ant",
      "image_url": "https://cdn.example.com/images/ant.png",
      "audio_url": "https://cdn.example.com/audio/ant.mp3",
      "is_correct": true
    },
    {
      "title": "ball",
      "image_url": "https://cdn.example.com/images/ball.png",
      "audio_url": "https://cdn.example.com/audio/ball.mp3",
      "is_correct": false
    }
  ]
}
```

#### Fields

| Field | Type | Required | Notes |
|---|---|---|---|
| `title` | `string` | yes | Step title |
| `instruction_text` | `string` | yes | On-screen instruction |
| `duration_seconds` | `int` | yes | Length of the game in seconds |
| `passing_score` | `int` | yes | Minimum correct taps required to pass |
| `instruction_audio_url` | `string` | no | Audio for the instruction |
| `target_sound` | `string` | no | The phoneme being practised |
| `options` | `object[]` | yes, min 2 | Selectable game options |
| `options[].title` | `string` | yes | Option label |
| `options[].image_url` | `string` | yes | Option image |
| `options[].audio_url` | `string` | yes | Audio played when the option is tapped |
| `options[].is_correct` | `bool` | yes | At least **one** must be `true` |

---

### 10. `sound_presence_check`

**Purpose:** Yes/no questions where the learner decides whether a target sound is present in a word.

#### Config shape

```json
{
  "title": "Does it have /a/?",
  "questions": [
    {
      "prompt": "Does 'apple' have the /a/ sound?",
      "prompt_audio_url": "https://cdn.example.com/audio/q1_prompt.mp3",
      "word_text": "apple",
      "word_audio_url": "https://cdn.example.com/audio/apple.mp3",
      "target_sound": "a",
      "correct_answer": true,
      "yes_label": "Yes",
      "no_label": "No"
    },
    {
      "prompt": "Does 'dog' have the /a/ sound?",
      "prompt_audio_url": "https://cdn.example.com/audio/q2_prompt.mp3",
      "word_text": "dog",
      "word_audio_url": "https://cdn.example.com/audio/dog.mp3",
      "target_sound": "a",
      "correct_answer": false,
      "yes_label": "Yes",
      "no_label": "No"
    }
  ]
}
```

#### Fields

| Field | Type | Required | Notes |
|---|---|---|---|
| `title` | `string` | yes | Step title |
| `questions` | `object[]` | yes, min 1 | List of yes/no questions |
| `questions[].prompt` | `string` | yes | Question text |
| `questions[].word_audio_url` | `string` | yes | Audio of the word being evaluated |
| `questions[].target_sound` | `string` | yes | The phoneme to check for |
| `questions[].correct_answer` | `bool` | yes | `true` if the sound is present, `false` if not |
| `questions[].yes_label` | `string` | yes | Label for the yes button (default: `"Yes"`) |
| `questions[].no_label` | `string` | yes | Label for the no button (default: `"No"`) |
| `questions[].prompt_audio_url` | `string` | no | Audio of the question |
| `questions[].word_text` | `string` | no | Display text of the word |

---

### 11. `missing_letters`

**Purpose:** Fill-in-the-blank spelling activity. The learner picks letters from a provided list to complete a word.

#### Config shape

```json
{
  "title": "Spell the word",
  "instruction_text": "Fill in the missing letters",
  "instruction_audio_url": "https://cdn.example.com/audio/ml_instr.mp3",
  "activities": [
    {
      "prompt_text": "cat",
      "target_word": "cat",
      "answer_template": [
        { "value": "c", "kind": "given" },
        { "value": "a", "kind": "missing" },
        { "value": "t", "kind": "given" }
      ],
      "options": ["a", "e", "i", "o"]
    }
  ]
}
```

#### Fields

| Field | Type | Required | Notes |
|---|---|---|---|
| `title` | `string` | yes | Step title |
| `instruction_text` | `string` | yes | On-screen instruction |
| `instruction_audio_url` | `string` | no | Audio for the instruction |
| `activities` | `object[]` | yes, min 1 | Spelling activities |
| `activities[].prompt_text` | `string` | yes | The word shown to the learner |
| `activities[].target_word` | `string` | yes | The correct full spelling |
| `activities[].answer_template` | `object[]` | yes, min 1 | Ordered letter slots for the word |
| `answer_template[].value` | `string` | yes | The letter at this position |
| `answer_template[].kind` | `string` | yes | `"given"` (pre-filled) or `"missing"` (blank the learner must fill) |
| `activities[].options` | `string[]` | yes, min 2 | Flat list of letter choices — every `missing` value **must** appear here |

> **Rule:** Every `answer_template` entry with `kind: "missing"` must have its `value` present in `options`. The frontend should validate this before rendering.

---

### 12. `matching_words`

**Purpose:** The learner matches a prompt (a sound or an image) to the correct word or image from a set of options. Three modes are supported.

#### Modes

| Mode | Prompt | Options must include |
|---|---|---|
| `sound_to_image` | `prompt_audio_url` (required) | `image_url` on each option (required) |
| `sound_to_word` | `prompt_audio_url` (required) | `label` only |
| `image_to_word` | `prompt_image_url` (required) | `label` only |

#### Config shape

```json
{
  "title": "Match the word",
  "instruction_audio_url": "https://cdn.example.com/audio/mw_instr.mp3",
  "activities": [
    {
      "mode": "sound_to_image",
      "prompt_text": "Which picture matches the word you hear?",
      "prompt_audio_url": "https://cdn.example.com/audio/cat.mp3",
      "correct_option_id": "opt_cat",
      "options": [
        {
          "id": "opt_cat",
          "label": "cat",
          "image_url": "https://cdn.example.com/images/cat.png"
        },
        {
          "id": "opt_dog",
          "label": "dog",
          "image_url": "https://cdn.example.com/images/dog.png"
        },
        {
          "id": "opt_sun",
          "label": "sun",
          "image_url": "https://cdn.example.com/images/sun.png"
        }
      ]
    }
  ]
}
```

#### Fields

| Field | Type | Required | Notes |
|---|---|---|---|
| `title` | `string` | yes | Step title |
| `instruction_audio_url` | `string` | no | Instruction audio |
| `activities` | `object[]` | yes, min 1 | Matching activities |
| `activities[].mode` | `string` | yes | One of: `"sound_to_image"`, `"sound_to_word"`, `"image_to_word"` |
| `activities[].prompt_text` | `string` | yes | On-screen prompt text |
| `activities[].correct_option_id` | `string` | yes | Must match the `id` of one option in the array |
| `activities[].prompt_audio_url` | `string` | conditional | Required for `sound_to_image` and `sound_to_word` |
| `activities[].prompt_image_url` | `string` | conditional | Required for `image_to_word` |
| `activities[].options` | `object[]` | yes, min 2 | Answer options |
| `options[].id` | `string` | yes | Unique identifier within this activity |
| `options[].label` | `string` | yes | Text label for the option |
| `options[].image_url` | `string` | conditional | Required when mode is `sound_to_image` |

---

### 13. `word_reading`

**Purpose:** Full word reading with an image, full-word audio, and a per-grapheme phoneme breakdown. The learner can tap individual segments to hear them.

#### Config shape

```json
{
  "title": "Read the words",
  "instruction_audio_url": "https://cdn.example.com/audio/wr_instr.mp3",
  "items": [
    {
      "word": "cat",
      "image_url": "https://cdn.example.com/images/cat.png",
      "word_audio_url": "https://cdn.example.com/audio/cat.mp3",
      "model_reading_label": "Listen",
      "segments": [
        {
          "label": "c",
          "audio_url": "https://cdn.example.com/audio/k.mp3",
          "highlighted": false
        },
        {
          "label": "a",
          "audio_url": "https://cdn.example.com/audio/ae.mp3",
          "highlighted": true
        },
        {
          "label": "t",
          "audio_url": "https://cdn.example.com/audio/t.mp3",
          "highlighted": false
        }
      ]
    }
  ]
}
```

#### Fields

| Field | Type | Required | Notes |
|---|---|---|---|
| `title` | `string` | yes | Step title |
| `instruction_audio_url` | `string` | no | Instruction audio |
| `items` | `object[]` | yes, min 1 | Words to read |
| `items[].word` | `string` | yes | The word text |
| `items[].image_url` | `string` | yes | Image illustrating the word |
| `items[].word_audio_url` | `string` | yes | Audio of the full word |
| `items[].model_reading_label` | `string` | no | Label for the model-reading button (e.g. `"Listen"`) |
| `items[].segments` | `object[]` | yes, min 1 | Phoneme/grapheme breakdown |
| `segments[].label` | `string` | yes | The grapheme text (e.g. `"a"`) |
| `segments[].audio_url` | `string` | yes | Audio for this segment when tapped |
| `segments[].highlighted` | `bool` | yes | Marks the focus grapheme of the lesson |

---

### 14. `sentence_reading`

**Purpose:** Full sentence reading. The sentence is split into tokens so the app can highlight each word as it is read aloud.

#### Config shape

```json
{
  "title": "Read the sentence",
  "instruction_audio_url": "https://cdn.example.com/audio/sr_instr.mp3",
  "items": [
    {
      "sentence_text": "The cat sat on the mat.",
      "display_tokens": ["The", "cat", "sat", "on", "the", "mat."],
      "sentence_audio_url": "https://cdn.example.com/audio/sentence1.mp3",
      "self_read_label": "Now you read it"
    }
  ]
}
```

#### Fields

| Field | Type | Required | Notes |
|---|---|---|---|
| `title` | `string` | yes | Step title |
| `instruction_audio_url` | `string` | no | Instruction audio |
| `items` | `object[]` | yes, min 1 | Sentences to read |
| `items[].sentence_text` | `string` | yes | The full sentence string |
| `items[].display_tokens` | `string[]` | yes, min 1 | Flat list of word/token strings — used for word-by-word highlighting during playback |
| `items[].sentence_audio_url` | `string` | yes | Audio of the full sentence |
| `items[].self_read_label` | `string` | no | Label on the self-read prompt button |

---

### 15. `mini_story_card`

**Purpose:** A short illustrated story card with a heading, multi-line body text, and audio narration. Multiple cards can appear in one step.

#### Config shape

```json
{
  "title": "Read the story",
  "instruction_audio_url": "https://cdn.example.com/audio/story_instr.mp3",
  "items": [
    {
      "heading": "The Big Cat",
      "heading_audio_url": "https://cdn.example.com/audio/heading1.mp3",
      "body_lines": [
        "A big cat sat on a mat.",
        "The cat had a hat.",
        "The cat in the hat!"
      ],
      "story_audio_url": "https://cdn.example.com/audio/story1.mp3",
      "cta_label": "Read Again"
    }
  ]
}
```

#### Fields

| Field | Type | Required | Notes |
|---|---|---|---|
| `title` | `string` | yes | Step title |
| `instruction_audio_url` | `string` | no | Instruction audio |
| `items` | `object[]` | yes, min 1 | Story cards |
| `items[].heading` | `string` | yes | Story title/heading text |
| `items[].body_lines` | `string[]` | yes, min 1 | Flat list of strings — each entry is one line of story body text |
| `items[].story_audio_url` | `string` | yes | Audio narration of the full story |
| `items[].heading_audio_url` | `string` | no | Audio for the heading only |
| `items[].cta_label` | `string` | no | Label for the replay or CTA button (e.g. `"Read Again"`) |

---

*End of document.*
