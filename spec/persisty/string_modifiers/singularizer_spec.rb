module Persisty
  module StringModifiers
    describe Singularizer do
      it_behaves_like 'a StringModifier object'

      context 'when word is empty' do
        it 'returns empty string' do
          expect(subject.singularize('')).to eql ''
        end
      end

      context 'when word is already singular' do
        it "returns word only" do
          expect(subject.singularize('salary')).to eql 'salary'
          expect(subject.singularize('query')).to eql 'query'
          expect(subject.singularize('pythony')).to eql 'pythony'
          expect(subject.singularize('SALARY')).to eql 'SALARY'
          expect(subject.singularize('QUERY')).to eql 'QUERY'
          expect(subject.singularize('PYTHONY')).to eql 'PYTHONY'
          expect(subject.singularize('bus')).to eql 'bus'
          expect(subject.singularize('church')).to eql 'church'
          expect(subject.singularize('fox')).to eql 'fox'
          expect(subject.singularize('push')).to eql 'push'
          expect(subject.singularize('swoosh')).to eql 'swoosh'
          expect(subject.singularize('woz')).to eql 'woz'
          expect(subject.singularize('BUS')).to eql 'BUS'
          expect(subject.singularize('CHURCH')).to eql 'CHURCH'
          expect(subject.singularize('FOX')).to eql 'FOX'
          expect(subject.singularize('PUSH')).to eql 'PUSH'
          expect(subject.singularize('SWOOSH')).to eql 'SWOOSH'
          expect(subject.singularize('WOZ')).to eql 'WOZ'
          expect(subject.singularize('stomach')).to eql 'stomach'
          expect(subject.singularize('epoch')).to eql 'epoch'
          expect(subject.singularize('STOMACH')).to eql 'STOMACH'
          expect(subject.singularize('EPOCH')).to eql 'EPOCH'
          expect(subject.singularize('knife')).to eql 'knife'
          expect(subject.singularize('wife')).to eql 'wife'
          expect(subject.singularize('half')).to eql 'half'
          expect(subject.singularize('scarf')).to eql 'scarf'
          expect(subject.singularize('KNIFE')).to eql 'KNIFE'
          expect(subject.singularize('WIFE')).to eql 'WIFE'
          expect(subject.singularize('HALF')).to eql 'HALF'
          expect(subject.singularize('SCARF')).to eql 'SCARF'
          expect(subject.singularize('chief')).to eql 'chief'
          expect(subject.singularize('spoof')).to eql 'spoof'
          expect(subject.singularize('beef')).to eql 'beef'
          expect(subject.singularize('CHIEF')).to eql 'CHIEF'
          expect(subject.singularize('SPOOF')).to eql 'SPOOF'
          expect(subject.singularize('BEEF')).to eql 'BEEF'
          expect(subject.singularize('solo')).to eql 'solo'
          expect(subject.singularize('zero')).to eql 'zero'
          expect(subject.singularize('studio')).to eql 'studio'
          expect(subject.singularize('zoo')).to eql 'zoo'
          expect(subject.singularize('SOLO')).to eql 'SOLO'
          expect(subject.singularize('ZERO')).to eql 'ZERO'
          expect(subject.singularize('STUDIO')).to eql 'STUDIO'
          expect(subject.singularize('ZOO')).to eql 'ZOO'
          expect(subject.singularize('tomato')).to eql 'tomato'
          expect(subject.singularize('potato')).to eql 'potato'
          expect(subject.singularize('hero')).to eql 'hero'
          expect(subject.singularize('TOMATO')).to eql 'TOMATO'
          expect(subject.singularize('POTATO')).to eql 'POTATO'
          expect(subject.singularize('HERO')).to eql 'HERO'
          expect(subject.singularize('person')).to eql 'person'
          expect(subject.singularize('zombie')).to eql 'zombie'
          expect(subject.singularize('child')).to eql 'child'
          expect(subject.singularize('PERSON')).to eql 'Person'
          expect(subject.singularize('ZOMBIE')).to eql 'ZOMBIE'
          expect(subject.singularize('CHILD')).to eql 'CHILD'
        end
      end

      context "when word ends with 'ies'" do
        it "returns correct 'y' singular" do
          expect(subject.singularize('salaries')).to eql 'salary'
          expect(subject.singularize('queries')).to eql 'query'
          expect(subject.singularize('pythonies')).to eql 'pythony'
          expect(subject.singularize('SALARIES')).to eql 'SALARy'
          expect(subject.singularize('QUERIES')).to eql 'QUERy'
          expect(subject.singularize('PYTHONIES')).to eql 'PYTHONy'
        end
      end

      context "when word ends with 's', 'z', 'ch', 'x' or 'sh'" do
        it "returns correct singular for 's', 'z', 'ch', 'x' or 'sh'" do
          expect(subject.singularize('buses')).to eql 'bus'
          expect(subject.singularize('churches')).to eql 'church'
          expect(subject.singularize('foxes')).to eql 'fox'
          expect(subject.singularize('pushes')).to eql 'push'
          expect(subject.singularize('swooshes')).to eql 'swoosh'
          expect(subject.singularize('wozes')).to eql 'woz'
          expect(subject.singularize('BUSES')).to eql 'BUS'
          expect(subject.singularize('CHURCHES')).to eql 'CHURCH'
          expect(subject.singularize('FOXES')).to eql 'FOX'
          expect(subject.singularize('PUSHES')).to eql 'PUSH'
          expect(subject.singularize('SWOOSHES')).to eql 'SWOOSH'
          expect(subject.singularize('WOZES')).to eql 'WOZ'
        end

        it "returns correct singular for 'ch' exceptions" do
          expect(subject.singularize('stomachs')).to eql 'stomach'
          expect(subject.singularize('epochs')).to eql 'epoch'
          expect(subject.singularize('STOMACHS')).to eql 'STOMACH'
          expect(subject.singularize('EPOCHS')).to eql 'EPOCH'
        end
      end

      context "when word ends with 'ves'" do
        it "returns correct 'f' or 'fe' singulars" do
          expect(subject.singularize('knives')).to eql 'knife'
          expect(subject.singularize('wives')).to eql 'wife'
          expect(subject.singularize('halves')).to eql 'half'
          expect(subject.singularize('scarves')).to eql 'scarf'
          expect(subject.singularize('KNIVES')).to eql 'KNIfe'
          expect(subject.singularize('WIVES')).to eql 'WIfe'
          expect(subject.singularize('HALVES')).to eql 'HALf'
          expect(subject.singularize('SCARVES')).to eql 'SCARf'
        end

        it "returns correct singular for 'f' exceptions" do
          expect(subject.singularize('chiefs')).to eql 'chief'
          expect(subject.singularize('spoofs')).to eql 'spoof'
          expect(subject.singularize('beefs')).to eql 'beef'
          expect(subject.singularize('CHIEFS')).to eql 'CHIEF'
          expect(subject.singularize('SPOOFS')).to eql 'SPOOF'
          expect(subject.singularize('BEEFS')).to eql 'BEEF'
        end
      end

      context "when word ends with 'os'" do
        it "returns correct singular" do
          expect(subject.singularize('solos')).to eql 'solo'
          expect(subject.singularize('zeros')).to eql 'zero'
          expect(subject.singularize('studios')).to eql 'studio'
          expect(subject.singularize('zoos')).to eql 'zoo'
          expect(subject.singularize('SOLOS')).to eql 'SOLO'
          expect(subject.singularize('ZEROS')).to eql 'ZERO'
          expect(subject.singularize('STUDIOS')).to eql 'STUDIO'
          expect(subject.singularize('ZOOS')).to eql 'ZOO'
        end

        it "returns correct singular for 'o' exceptions" do
          expect(subject.singularize('tomatoes')).to eql 'tomato'
          expect(subject.singularize('potatoes')).to eql 'potato'
          expect(subject.singularize('heroes')).to eql 'hero'
          expect(subject.singularize('TOMATOES')).to eql 'TOMATO'
          expect(subject.singularize('POTATOES')).to eql 'POTATO'
          expect(subject.singularize('HEROES')).to eql 'HERO'
        end
      end

      context 'when word has irregular plural' do
        it 'returns correct singular for each case' do
          expect(subject.singularize('people')).to eql 'person'
          expect(subject.singularize('zombies')).to eql 'zombie'
          expect(subject.singularize('children')).to eql 'child'
          expect(subject.singularize('PEOPLE')).to eql 'Person'
          expect(subject.singularize('ZOMBIES')).to eql 'ZOMBIE'
          expect(subject.singularize('CHILDREN')).to eql 'CHILD'
        end
      end

      context 'when word has regular plural' do
        it 'returns correct singular for each case' do
          expect(subject.singularize('tests')).to eql 'test'
          expect(subject.singularize('employees')).to eql 'employee'
          expect(subject.singularize('skills')).to eql 'skill'
          expect(subject.singularize('papers')).to eql 'paper'
          expect(subject.singularize('TESTS')).to eql 'TEST'
          expect(subject.singularize('EMPLOYEES')).to eql 'EMPLOYEE'
          expect(subject.singularize('SKILLS')).to eql 'SKILL'
          expect(subject.singularize('PAPERS')).to eql 'PAPER'
        end
      end
    end
  end
end
