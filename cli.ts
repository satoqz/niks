import {
  colors,
  Command,
  CompletionsCommand,
  HelpCommand,
  Table,
} from "https://deno.land/x/cliffy@v0.25.5/mod.ts";

import NixProfile from "./lib.ts";

const list = new Command()
  .description("List installed packages.")
  .alias("l")
  .option("-r --raw", "Unformatted output without header")
  .action(async ({ raw }) => {
    const profile = await NixProfile.init();

    const data = [...profile.packages.entries()].flatMap(([name, pkgs]) =>
      pkgs.map((pkg) => [name, pkg.path])
    );

    if (!data.length) {
      return console.error(colors.brightRed("No packages installed."));
    }

    if (raw) {
      new Table().body(data).render();
    } else {
      new Table().header([
        "Name",
        "Store Path",
      ]).body(
        data.map((
          [name, path],
        ) => [colors.white(name), colors.brightBlue(path)]),
      ).render();
    }
  });

const install = new Command()
  .description("Install packages.")
  .alias("i")
  .arguments("<...pkgs>")
  .action(async (_, ...pkgs) => {
    const profile = await NixProfile.init();
    for (const pkg of pkgs) {
      await profile.install(pkg);
      console.error(colors.brightGreen(`Installed package ${pkg}.`));
    }
  });

const remove = new Command()
  .description("Remove packages.")
  .alias("r")
  .arguments("<...pkgs>")
  .action(async (_, ...pkgs) => {
    const profile = await NixProfile.init();
    for (const pkg of pkgs) {
      await profile.remove(pkg);
      console.error(colors.brightRed(`Removed package ${pkg}.`));
    }
  });

const upgrade = new Command()
  .description("Upgrade packages.")
  .alias("u")
  .arguments("[...pkgs]")
  .action(async (_, ...maybePkgs) => {
    const profile = await NixProfile.init();

    const pkgs = maybePkgs.length ? maybePkgs : profile.packages.keys();

    for (const pkg of pkgs) {
      await profile.upgrade(pkg);
    }

    console.error(colors.brightGreen(`Upgraded packages.`));
  });

const root = new Command()
  .name("niks")
  .version("0.1.0")
  .description(
    `${colors.magenta("niks")} - command line wrapper around ${
      colors.brightBlack("`nix profile`")
    }, because it sucks.`,
  )
  .default("help")
  .command("help", new HelpCommand().global())
  .command("completions", new CompletionsCommand())
  .command("list", list)
  .command("install", install)
  .command("remove", remove)
  .command("upgrade", upgrade);

try {
  await root.parse(Deno.args);
} catch (error) {
  console.error(colors.red(error.message));
}
