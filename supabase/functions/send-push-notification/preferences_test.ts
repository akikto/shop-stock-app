import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";

import { isPushEnabledForType } from "./preferences.ts";

Deno.test("push enabled when preference row is missing", () => {
  assertEquals(isPushEnabledForType("sale", null), true);
  assertEquals(isPushEnabledForType("low_stock", null), true);
});

Deno.test("push disabled only when preference is explicitly false", () => {
  assertEquals(
    isPushEnabledForType("sale", { notify_sale: false }),
    false,
  );
  assertEquals(
    isPushEnabledForType("sale", { notify_sale: true }),
    true,
  );
  assertEquals(
    isPushEnabledForType("stock_in", { notify_stock_in: false }),
    false,
  );
});

Deno.test("system notifications always allow push", () => {
  assertEquals(
    isPushEnabledForType("system", { notify_sale: false }),
    true,
  );
});

Deno.test("unknown notification types do not send push", () => {
  assertEquals(isPushEnabledForType("unknown", null), false);
});
