// Test keyboard text entry on chat textarea
import { a11y, openDebugPage } from '../support/browser.mjs';
import { clickSemanticButtonContaining } from '../support/semantic_actions.mjs';

const { browser, page } = await openDebugPage({
  gotoOptions: { timeout: 20000 },
  launchOptions: { args: ['--no-sandbox'] },
  settleMs: 2000,
  enableAccessibility: true,
  accessibilitySettleMs: 2000,
});

// Navigate to Support Triage chat
await clickSemanticButtonContaining(page, 'Support Triage');
await page.waitForTimeout(3000);
console.log('URL:', page.url());

// 2. Find the chat input
const inputInfo = await page.evaluate(() => {
  const ta = document.querySelector('textarea[aria-label="Message Gormes"]');
  if (!ta) return {found: false, allTextareas: document.querySelectorAll('textarea').length};
  const rect = ta.getBoundingClientRect();
  const sem = ta.closest('flt-semantics');
  return {
    found: true, 
    tag: ta.tagName, 
    disabled: ta.disabled,
    rect: {x: Math.round(rect.x), y: Math.round(rect.y), w: Math.round(rect.width), h: Math.round(rect.height)},
    semRect: sem ? {x: Math.round(sem.getBoundingClientRect().x), y: Math.round(sem.getBoundingClientRect().y), w: Math.round(sem.getBoundingClientRect().width), h: Math.round(sem.getBoundingClientRect().height)} : null
  };
});
console.log('Input:', JSON.stringify(inputInfo, null, 2));

if (inputInfo.found) {
  // 3. Click at the textarea position (not the disabled element, but the region)
  await page.mouse.click(inputInfo.rect.x + 10, inputInfo.rect.y + 10);
  await page.waitForTimeout(500);
  
  // 4. Press keys and see if they get typed
  await page.keyboard.type('hello from keyboard');
  await page.waitForTimeout(500);
  
  // 5. Check value
  const val1 = await page.evaluate(() => {
    const ta = document.querySelector('textarea[aria-label="Message Gormes"]');
    if (!ta) return 'not found';
    console.log('textarea value:', ta.value, 'disabled:', ta.disabled);
    return {value: ta.value, disabled: ta.disabled};
  });
  console.log('After keyboard type:', JSON.stringify(val1));
  
  // 6. Try clicking the semantics parent first
  if (inputInfo.semRect) {
    await page.mouse.click(inputInfo.semRect.x + 10, inputInfo.semRect.y + 10);
    await page.waitForTimeout(500);
    await page.keyboard.press('Control+a');
    await page.keyboard.type(' typed again');
    await page.waitForTimeout(500);
    
    const val2 = await page.evaluate(() => {
      const ta = document.querySelector('textarea[aria-label="Message Gormes"]');
      return ta ? {value: ta.value, disabled: ta.disabled} : null;
    });
    console.log('After 2nd attempt:', JSON.stringify(val2));
  }
  
  // 7. Try pressing Enter to send (or click send button)
  await page.keyboard.press('Enter');
  await page.waitForTimeout(2000);
  
  const texts = await page.evaluate(() => {
    const sems = document.querySelectorAll('flt-semantics');
    return [...new Set(Array.from(sems).map(s => (s.textContent||'').trim()).filter(t => t && t.length > 5))].slice(0,10);
  });
  console.log('Texts after Enter:', JSON.stringify(texts));
}

await page.screenshot({path:'/tmp/navivox-keyboard.png'});
await browser.close();