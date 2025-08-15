const express = require('express');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());
app.use(express.text());

function removeEmDash(text) {
  if (!text || typeof text !== 'string') {
    return text;
  }
  
  function isDateTimeOrPeriod(str) {
    const dateTimePatterns = [
      /^\d+:\d+/,  
      /^\d+$/,     // number.. could be date, who knows
      /^(January|February|March|April|May|June|July|August|September|October|November|December|Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)$/i,  // this is dumb
      /^(Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday|Mon|Tue|Wed|Thu|Fri|Sat|Sun)$/i,  // days
      /^(Spring|Summer|Fall|Autumn|Winter)$/i,  // seasons, did you see that, even autumn my zoul!
      /^\d{4}$/,   
      /^Q[1-4]$/i, // quarters for that jerome powell post
    ];
    return dateTimePatterns.some(pattern => pattern.test(str.trim()));
  }

  let result = text
    // 1. parenthetical/interruptive information (word — phrase — word) -> parentheses
    .replace(/([a-zA-Z])\s*—\s*([^—]+?)\s*—\s*([a-zA-Z])/g, '$1 ($2) $3')
    
    // 2. date/time ranges (handle early to avoid conflicts)
    .replace(/(\d+:\d+\s*[ap]\.?m\.?)\s*—\s*(\d+:\d+\s*[ap]\.?m\.?)/gi, '$1 to $2')
    
    // 3. interrupted speech in dialogue (word—") -> keep as interruption (but clean format)
    .replace(/([a-zA-Z])\s*—\s*$/g, '$1 – ')
    
    // 4. attribution quotes ("quote" — Author) -> en dash
    .replace(/"([^"]+)"\s*—\s*([A-Z][^.!?]*)/g, '"$1" – $2')
    
    // 5. dramatic pause/reveal (phrase — Word!) -> ellipsis
    .replace(/([a-zA-Z\s]+)\s*—\s*([A-Z][a-zA-Z]*[!.])/g, '$1 ... $2')
    
    // 6. sudden break in thought (clause — but/and/or...) -> comma
    .replace(/([a-zA-Z])\s*—\s*(but|and|or|yet|so)\s+/g, '$1, $2 ')
    
    // 7. appositive emphasis (noun — a descriptor) -> comma
    .replace(/([a-zA-Z])\s*—\s*(a\s+[a-zA-Z][^.!?]*)/g, '$1, $2')
    
    // 8. summary/amplification at end (items — conclusion.) -> semicolon
    .replace(/([a-zA-Z.,\s]*[a-zA-Z.,])\s*—\s*([a-z][^.!?]*\.)/g, '$1 ; $2')
    
    // 9. after sentence punctuation -> space
    .replace(/([.!?:;])\s*—\s*([A-Za-z])/g, '$1 $2')
    
    // 10. after comma -> space
    .replace(/([,])\s*—\s*([A-Za-z])/g, '$1 $2')
    
    // 11. before closing punctuation -> space
    .replace(/([a-zA-Z])\s*—\s*([.,;:!?"'\)\]])/g, '$1 $2')
    
    // 12. after opening punctuation -> space
    .replace(/(["'(\[])\s*—\s*([A-Za-z])/g, '$1 $2')
    
    // 13. between letters (simple cases) -> comma
    .replace(/([a-zA-Z])\s*—\s*([a-zA-Z])/g, '$1, $2')
    
    // 14. leading em dash -> remove
    .replace(/^\s*—\s*/g, '')
    
    // 15. trailing em dash -> remove
    .replace(/\s*—\s*$/g, '')
    
    // 16. catch-all remaining -> check if it's a date/time range, otherwise en dash
    .replace(/(\S+)\s*—\s*(\S+)/g, (_, left, right) => {
      if (isDateTimeOrPeriod(left) && isDateTimeOrPeriod(right)) {
        return `${left} – ${right}`;
      }
      return `${left} – ${right}`;
    });

  // sanitation step: clean up spacing issues
  result = result
    // remove spaces before colons and ellipses
    .replace(/\s+\.\.\./g, '...')
    .replace(/\s+:/g, ':')
    .replace(/\s+;/g, ';')
    // clean up multiple spaces
    .replace(/\s+/g, ' ')
    .trim();

  return result;
}

app.post('/emdash', (req, res) => {
  try {
    const text = typeof req.body === 'string' ? req.body : req.body.text;
    
    if (!text) {
      return res.status(400).json({ error: 'Text is required, come on now' });
    }

    const result = removeEmDash(text);
    res.json({ 
      original: text,
      result: result 
    });
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/emdash', (req, res) => {
  const text = req.query.text;
  
  if (!text) {
    return res.status(400).json({ error: 'Text query parameter is required, come on now' });
  }

  const result = removeEmDash(text);
  res.json({ 
    original: text,
    result: result 
  });
});

app.get('/', (req, res) => {
  res.json({
    message: 'Em Dash API',
    description: 'API to linguistically and grammatically replace em dashes.',
    endpoints: {
      'POST /emdash': 'Send text in body (JSON or plain text)',
      'GET /emdash?text=your-text': 'Send text as query parameter'
    }
  });
});


app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});